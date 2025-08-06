// lib/exceptions/geometry_exceptions.dart
/// Base class for all geometry-related exceptions
abstract class GeometryException implements Exception {
  final String message;
  final Object? cause;

  const GeometryException(this.message, [this.cause]);

  @override
  String toString() =>
      'GeometryException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when geometric objects have invalid parameters
class InvalidGeometricObjectException extends GeometryException {
  const InvalidGeometricObjectException(super.message, [super.cause]);

  @override
  String toString() =>
      'InvalidGeometricObjectException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when intersection calculations fail
class IntersectionCalculationException extends GeometryException {
  const IntersectionCalculationException(super.message, [super.cause]);

  @override
  String toString() =>
      'IntersectionCalculationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when trying to create invalid constructions
class InvalidConstructionException extends GeometryException {
  const InvalidConstructionException(super.message, [super.cause]);

  @override
  String toString() =>
      'InvalidConstructionException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
