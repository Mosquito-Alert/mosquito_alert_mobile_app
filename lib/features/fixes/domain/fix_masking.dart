/// Size, in decimal degrees, of the grid cell that background fixes are masked
/// to before they leave the phone.
const double fixMaskGridSize = 0.025;

/// Tolerance of the masking, in grid cells. See [maskCoordinate].
const double _gridGuard = 1e-9;

/// Masks one coordinate of a background fix (a latitude or a longitude, in
/// decimal degrees) by rounding it **down** to the grid.
///
/// Applied to both coordinates, this gives the south-west corner of the
/// [gridSize] cell the phone is in. That is what the server stores and what the
/// sampling effort data are built from, so the direction matters: rounding to
/// the nearest grid point instead puts three fixes out of four in a
/// neighbouring cell.
///
/// "Down" means towards minus infinity. West of Greenwich and south of the
/// equator the result is still the south-west corner: -3.7038 gives -3.725,
/// not -3.7.
///
/// Masking a value that is already masked returns it unchanged. This is needed
/// because a fix is masked again every time its request is rebuilt from the
/// outbox or from a stored model. A multiple of 0.025 is not exact in floating
/// point, so a plain `floor()` would move about 7% of the grid values one cell
/// south or west on the next pass (2.15 would become 2.125). The guard of a
/// billionth of a cell, about three thousandths of a millimetre on the ground,
/// prevents that and is far below the precision of any position.
double maskCoordinate(double value, {double gridSize = fixMaskGridSize}) =>
    ((value / gridSize) + _gridGuard).floor() * gridSize;
