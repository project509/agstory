extends RefCounted
## Base class for all unit tests. Subclass, then write methods named test_*.

var _failures: Array[String] = []
var assertions := 0

func _reset() -> void:
    _failures = []

func get_failures() -> Array[String]:
    return _failures

func fail(msg: String) -> void:
    _failures.append(msg)

func assert_true(cond: bool, msg := "") -> void:
    assertions += 1
    if not cond:
        fail("expected true; %s" % msg)

func assert_false(cond: bool, msg := "") -> void:
    assertions += 1
    if cond:
        fail("expected false; %s" % msg)

func assert_eq(actual, expected, msg := "") -> void:
    assertions += 1
    if actual != expected:
        fail("expected %s, got %s; %s" % [str(expected), str(actual), msg])

func assert_ne(actual, expected, msg := "") -> void:
    assertions += 1
    if actual == expected:
        fail("expected != %s; %s" % [str(expected), msg])

func assert_almost(actual: float, expected: float, tol := 0.0001, msg := "") -> void:
    assertions += 1
    if absf(actual - expected) > tol:
        fail("expected ~%f, got %f; %s" % [expected, actual, msg])

func assert_in_range(v: float, lo: float, hi: float, msg := "") -> void:
    assertions += 1
    if v < lo or v > hi:
        fail("expected %f in [%f, %f]; %s" % [v, lo, hi, msg])

func assert_has(coll, key, msg := "") -> void:
    assertions += 1
    if not (key in coll):
        fail("expected to contain %s; %s" % [str(key), msg])
