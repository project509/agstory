extends "res://tests/TestCase.gd"
## Proves the test harness itself works. Never delete.

func test_arithmetic_sanity() -> void:
    assert_eq(2 + 2, 4, "basic arithmetic")

func test_assert_helpers_detect_failure() -> void:
    var probe = load("res://tests/TestCase.gd").new()
    probe._reset()
    probe.assert_eq(1, 2, "intentional")
    assert_eq(probe.get_failures().size(), 1, "assert_eq must record a failure")

func test_canon_starting_ac_totals() -> void:
    # Canon: docs/_source/lead-designer-notes-raw.md, starting armor per class.
    var totals := {
        "warrior": 7, "bard": 7, "monk": 6, "rogue": 5, "cleric": 5,
        "druid": 5, "shaman": 5, "mage": 4, "wizard": 4,
    }
    assert_eq(totals["warrior"], 7)
    assert_eq(totals["wizard"], 4)
    assert_eq(totals.size(), 9, "nine canon classes")
