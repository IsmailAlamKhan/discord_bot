# Nickname Persistence

<cite>
**Referenced Files in This Document**   
- [db.dart](file://src/db.dart)
- [store_all_nick_names.dart](file://src/store_all_nick_names.dart)
- [member_change.dart](file://src/member_change.dart)
- [db.json](file://db.json)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Data Model Overview](#data-model-overview)
3. [Initialization Process](#initialization-process)
4. [Nickname Collection on Startup](#nickname-collection-on-startup)
5. [Real-time Nickname Updates](#real-time-nickname-updates)
6. [Data Flow and State Management](#data-flow-and-state-management)
7. [User Rejoin Restoration Logic](#user-rejoin-restoration-logic)
8. [CRUD Operations](#crud-operations)
9. [Persistence Mechanism](#persistence-mechanism)
10. [Concurrency and Data Consistency](#concurrency-and-data-consistency)

## Introduction
The nickname persistence system in the Discord bot maintains user nickname history across server sessions. This documentation details how the system captures, stores, and restores user nicknames using an in-memory database with file-based persistence. The system ensures that users cannot evade their established nicknames by leaving and rejoining the server, maintaining social accountability within the community.

**Section sources**
- [db.dart](file://src/db.dart#L1-L132)
- [store_all_nick_names.dart](file://src/store_all_nick_names.dart#L1-L38)
- [member_change.dart](file://src/member_change.dart#L1-L78)

## Data Model Overview

The nickname persistence system centers around the `DB` class which maintains a `userNicknames` map as part of its state. This map stores Discord user IDs as string keys and their corresponding nicknames as string values.

```mermaid
classDiagram
class DB {
+Map<int, int> waifuPoints
+List<UserWaifuPreference> userWaifuPreferences
+Map<String, String> userNicknames
+String? getUserNickname(String userId)
+DB setUserNickname(String userId, String nickname)
+DB setMultipleUserNicknames(Map<String, String> userNicknames)
}
class DBController {
-DB? _db
+void init()
+void setDB(DB db)
+void getDBFromFile()
+void updateDB(DB Function(DB db) fn)
+T getFromDB<T>(T Function(DB db) fn)
}
class StoreAllNickNames {
-Ref ref
+Future<void> initialize()
}
class MemberChange {
-Ref ref
-StreamSubscription? _streamSubscription
-StreamSubscription? _streamSubscription2
+Future<void> start()
+Future<void> restart()
+Future<void> stop()
}
DBController --> DB : "manages"
StoreAllNickNames --> DBController : "uses"
MemberChange --> DBController : "uses"
StoreAllNickNames --> MemberChange : "complementary"
```

**Diagram sources**
- [db.dart](file://src/db.dart#L1-L132)

**Section sources**
- [db.dart](file://src/db.dart#L1-L132)

## Initialization Process

The nickname persistence system initializes through Riverpod's dependency injection framework. The `dbProvider` creates a `DBController` instance that automatically calls its `init()` method, which in turn invokes `getDBFromFile()` to load existing data from `db.json`. If the file doesn't exist, it's created with empty data structures.

When the bot starts, the system reads the JSON file and deserializes it into the in-memory `DB` object, making all previously stored nicknames immediately available for use. This initialization occurs before any other components attempt to access the database.

```mermaid
sequenceDiagram
participant Bot as Bot Startup
participant Provider as dbProvider
participant Controller as DBController
participant File as db.json
Bot->>Provider : Create dbProvider
Provider->>Controller : Initialize DBController
Controller->>Controller : init()
Controller->>Controller : getDBFromFile()
Controller->>File : Check if db.json exists
alt File exists
File-->>Controller : Return file contents
Controller->>Controller : Parse JSON
Controller->>Controller : Create DB instance
else File doesn't exist
Controller->>File : Create db.json
File-->>Controller : Empty file
Controller->>Controller : Create empty DB instance
end
Controller-->>Provider : DBController ready
Provider-->>Bot : Database system initialized
Note over Controller,File : Database loaded into memory<br/>Ready for operations
```

**Diagram sources**
- [db.dart](file://src/db.dart#L65-L88)

**Section sources**
- [db.dart](file://src/db.dart#L65-L88)

## Nickname Collection on Startup

The `StoreAllNickNames` class is responsible for collecting nicknames from all guild members when the bot starts. It uses the Discord API to fetch the complete list of members and their current nicknames, then bulk-populates the database.

```mermaid
flowchart TD
A[Bot Startup] --> B[Initialize StoreAllNickNames]
B --> C[Fetch Bot Instance]
C --> D[Get Guild Reference]
D --> E[Retrieve All Members]
E --> F{Process Each Member}
F --> G[Member has nickname?]
G --> |Yes| H[Add to nickNames Map]
G --> |No| I[Skip Member]
H --> J[Continue Processing]
I --> J
J --> K{All Members Processed?}
K --> |No| F
K --> |Yes| L[Update Database]
L --> M[Bulk Set Nicknames]
M --> N[System Ready]
style H fill:#D6EAF8,stroke:#1F618D
style I fill:#FADBD8,stroke:#C0392B
style M fill:#ABEBC6,stroke:#27AE60
```

The initialization process begins by obtaining the bot instance and environment configuration through Riverpod providers. It then creates a reference to the guild using the configured guild ID and retrieves all members with a single API call. For each member, it checks if both the user object and nickname are present, then stores the mapping of user ID to nickname in a temporary map. After processing all members, it updates the database atomically using the `setMultipleUserNicknames` method.

**Section sources**
- [store_all_nick_names.dart](file://src/store_all_nick_names.dart#L1-L38)

## Real-time Nickname Updates

The `MemberChange` class listens for Discord events that indicate nickname changes. It subscribes to two event streams: `onGuildMemberUpdate` for nickname modifications and `onGuildMemberAdd` for users rejoining the server.

```mermaid
sequenceDiagram
participant Discord as Discord API
participant Listener as MemberChange
participant DB as DBController
participant Database as db.json
Discord->>Listener : onGuildMemberUpdate event
Listener->>Listener : Extract member data
Listener->>Listener : Compare old vs new nickname
alt Nickname changed
Listener->>DB : updateDB()
DB->>DB : setUserNickname()
DB->>Database : Write updated JSON
Database-->>DB : Confirmation
DB-->>Listener : Update complete
else No change
Listener->>Listener : Ignore event
end
Discord->>Listener : onGuildMemberAdd event
Listener->>DB : getFromDB(getUserNickname)
DB-->>Listener : Return stored nickname
alt Nickname exists in DB
Listener->>Listener : Compare with current nickname
alt Different
Listener->>Discord : Update member nickname
Discord-->>Listener : Nickname set
Listener->>Discord : Send welcome message
end
end
Note over Listener,Database : Real-time synchronization<br/>between Discord events and database
```

When a member updates their nickname, the listener compares the old and new values. If a change is detected (and the new nickname is not null), it updates the database through the `updateDB` method, which ensures thread-safe modification of the shared state.

**Diagram sources**
- [member_change.dart](file://src/member_change.dart#L40-L55)

**Section sources**
- [member_change.dart](file://src/member_change.dart#L40-L55)

## Data Flow and State Management

The system uses Riverpod for state management, providing a clean separation between data access and business logic. The `dbProvider` serves as the single source of truth, accessible to all components that need to read or modify nickname data.

```mermaid
graph TB
subgraph "Discord Events"
A[onGuildMemberUpdate] --> B[MemberChange Listener]
C[onGuildMemberAdd] --> B
end
subgraph "State Management"
B --> D[dbProvider]
D --> E[DBController]
E --> F[In-Memory DB]
F --> G[db.json]
end
subgraph "Data Access"
H[StoreAllNickNames] --> D
I[Other Components] --> D
end
G --> |Load on startup| E
E --> |Save on change| G
style E fill:#E8DAEF,stroke:#884EA0
style G fill:#D5F5E3,stroke:#2E8B57
style D fill:#FEF9E7,stroke:#F4D03F
click E "src/db.dart" "DB Class"
click G "db.json" "Persistence File"
click D "src/db.dart" "dbProvider"
```

All components interact with the database through the provider system, ensuring consistent access patterns and proper dependency injection. The `updateDB` method provides a transaction-like interface for modifying the database, while `getFromDB` allows safe reading of data.

**Diagram sources**
- [db.dart](file://src/db.dart#L90-L132)
- [member_change.dart](file://src/member_change.dart#L1-L78)

**Section sources**
- [db.dart](file://src/db.dart#L90-L132)
- [member_change.dart](file://src/member_change.dart#L1-L78)

## User Rejoin Restoration Logic

When users leave and rejoin the server, the system automatically restores their previous nickname. This anti-evasion mechanism is implemented in the `onGuildMemberAdd` event listener.

The restoration process first checks the database for a stored nickname associated with the returning user. If found, it compares this stored nickname with the user's current nickname (which is typically null or their username when rejoining). If they differ, the system programmatically sets the nickname back to the original value and sends a humorous welcome message with a meme GIF to the designated channel.

This feature ensures that users cannot avoid their established nicknames by temporarily leaving the server, maintaining the social dynamics and inside jokes that have developed within the community.

```mermaid
flowchart TD
A[User Rejoins Server] --> B[onGuildMemberAdd Event]
B --> C[Query Database for Nickname]
C --> D{Nickname Exists?}
D --> |No| E[No Action]
D --> |Yes| F[Get Current Nickname]
F --> G{Different from Stored?}
G --> |No| H[No Action]
G --> |Yes| I[Update Nickname]
I --> J[Send Welcome Message]
J --> K[Process Complete]
style D fill:#D6EAF8,stroke:#1F618D
style G fill:#D6EAF8,stroke:#1F618D
style I fill:#ABEBC6,stroke:#27AE60
style J fill:#ABEBC6,stroke:#27AE60
style E,H fill:#FADBD8,stroke:#C0392B
linkStyle 5 stroke:#27AE60,fill:none
linkStyle 6 stroke:#27AE60,fill:none
```

**Diagram sources**
- [member_change.dart](file://src/member_change.dart#L57-L77)

**Section sources**
- [member_change.dart](file://src/member_change.dart#L57-L77)

## CRUD Operations

The nickname persistence system provides standard CRUD (Create, Read, Update) operations through the `DB` class methods:

```mermaid
stateDiagram-v2
[*] --> Idle
Idle --> Read : getUserNickname()
Read --> Idle : Return nickname or null
Idle --> Update : setUserNickname()
Update --> Validate : Check parameters
Validate --> Modify : Update map entry
Modify --> Persist : updateDB()
Persist --> Write : Serialize to JSON
Write --> Confirm : File write success
Confirm --> Idle : Operation complete
Idle --> BulkUpdate : setMultipleUserNicknames()
BulkUpdate --> Process : Iterate map entries
Process --> ModifyAll : Add all to userNicknames
ModifyAll --> Persist : updateDB()
Process --> Idle : Complete
note right of Update
Single nickname update
Used for real-time changes
end note
note left of BulkUpdate
Bulk nickname update
Used for initialization
end note
```

The `getUserNickname` method retrieves a nickname by user ID, returning null if no nickname is stored. The `setUserNickname` method creates or updates a single nickname mapping, while `setMultipleUserNicknames` efficiently adds multiple nickname mappings at once, used primarily during the startup collection process.

**Diagram sources**
- [db.dart](file://src/db.dart#L115-L130)

**Section sources**
- [db.dart](file://src/db.dart#L115-L130)

## Persistence Mechanism

The system uses a file-based persistence approach with JSON serialization. The `DBController` class handles all file operations, ensuring that the in-memory database state is synchronized with the `db.json` file on disk.

```mermaid
erDiagram
DATABASE {
string user_id PK
string nickname
datetime last_updated
}
PERSISTENCE {
string filename PK
string format
datetime last_write
int file_size
}
DATABASE ||--o{ PERSISTENCE : "serialized_as"
class DATABASE {
+Map<String, String> userNicknames
+Map<int, int> waifuPoints
+List<UserWaifuPreference> userWaifuPreferences
}
class PERSISTENCE {
+File db.json
+JSON format
+Atomic writes
}
```

The persistence mechanism works as follows:
1. All modifications go through the `updateDB` method
2. After each modification, `setDB` serializes the entire database state to JSON
3. The JSON string is written to `db.json` using `writeAsStringSync`
4. The file is created if it doesn't exist during initialization

This approach ensures data durability but may impact performance with frequent writes, as the entire database is written to disk for each change.

**Diagram sources**
- [db.dart](file://src/db.dart#L65-L88)
- [db.json](file://db.json)

**Section sources**
- [db.dart](file://src/db.dart#L65-L88)
- [db.json](file://db.json)

## Concurrency and Data Consistency

The current implementation addresses concurrency through Riverpod's provider system and the `updateDB` method's design. The `DBController` maintains a single instance of the database state, preventing multiple concurrent modifications.

However, the file-based persistence approach introduces potential race conditions. Since the entire database is written to disk after each change, rapid successive modifications could theoretically result in lost updates if the file system operations don't complete in sequence.

The system mitigates this risk through:
1. Synchronous file operations that block until completion
2. Single-threaded event processing from Discord
3. Atomic updates through the `updateDB` transaction pattern

Despite these measures, the lack of explicit locking mechanisms means that under high load, there's a small window for data inconsistency. Future improvements could include implementing a write queue or using a proper database system with transaction support.

The in-memory nature of the database provides fast read access but creates a single point of failure. If the bot crashes before a write operation completes, recent changes could be lost. The frequent serialization to disk minimizes this risk by ensuring most changes are persisted quickly.

**Section sources**
- [db.dart](file://src/db.dart#L90-L113)
- [member_change.dart](file://src/member_change.dart#L40-L55)