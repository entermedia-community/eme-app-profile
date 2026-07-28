import 'package:logger/logger.dart';

var _logger = Logger(printer: PrettyPrinter());

void logPrint(String message) {
  _logger.d(message);
}
