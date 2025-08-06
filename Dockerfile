# In the build stage
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code and AOT compile it.
COPY . .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
# RUN dart run bin/main.dart
CMD ["dart", "run", "bin/main.dart"]
# RUN dart run nyxx_commands:compile bin/main.dart -o bin/main
# RUN chmod +x /app/bin/main  # <--- Adding the execute permission

# # In the final image
# FROM scratch
# COPY --from=build /runtime/ /
# COPY --from=build /app/bin/main /app/bin/

# # Start server.
# EXPOSE 8080
# CMD ["/app/bin/main"]
