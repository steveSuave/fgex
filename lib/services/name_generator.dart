// lib/services/name_generator.dart
/// Generates unique names for geometric objects
class NameGenerator {

    // Private static instance
  static final NameGenerator _instance = NameGenerator._();

  // Private constructor
  NameGenerator._();

  // Public static getter to access the instance
  static NameGenerator get instance => _instance;

  int _pointCounter = 0;
  int _lineCounter = 0;
  int _circleCounter = 0;

  static const String _pointLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// Generates a unique name for a point
  String generatePointName() {
    if (_pointCounter < _pointLetters.length) {
      return _pointLetters[_pointCounter++];
    }
    return 'P${++_pointCounter}';
  }

  /// Generates a unique name for a line
  String generateLineName() => 'l${++_lineCounter}';

  /// Generates a unique name for a circle
  String generateCircleName() => 'c${++_circleCounter}';

  /// Resets all counters
  void reset() {
    _pointCounter = 0;
    _lineCounter = 0;
    _circleCounter = 0;
  }
}
