import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final _memoryOutput = MemoryLogOutput();

final logger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  output: MultiOutput([
    ConsoleOutput(),
    _memoryOutput,
  ]),
);

List<String> getLogHistory() => _memoryOutput.logs;

class MemoryLogOutput extends LogOutput {
  final List<String> logs = [];
  final int maxLogs = 50;

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      if (logs.length >= maxLogs) {
        logs.removeAt(0);
      }
      logs.add(line);
    }
  }
}

// Custom filter to only log in debug mode
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return kDebugMode || event.level == Level.error || event.level == Level.fatal;
  }
}
