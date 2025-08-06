import 'dart:async';

class MsgQueue {
  MsgQueue() {
    autoClearAfter10Minutes();
  }

  /// Map of user id to the number of requests they have made in the last 10 minutes
  final Map<int, int> messages = {};

  static const int maxMessages = 10;
  static const Duration maxAge = Duration(minutes: 10);

  /// Add a message to the queue
  /// and return true if one user has made 10 requests in the last 10 minutes
  bool addMessage(int userId) {
    int? count = messages[userId];

    if (count != null) {
      count += 1;
    } else {
      count = 1;
    }
    print('count: $count');
    messages[userId] = count;
    bool shouldShow = count > maxMessages;
    print('shouldShow: $shouldShow');
    return shouldShow;
  }

  /// Remove all messages from the queue
  void clear() {
    messages.clear();
  }

  void autoClearAfter10Minutes() {
    Timer.periodic(maxAge, (timer) => clear());
  }
}
