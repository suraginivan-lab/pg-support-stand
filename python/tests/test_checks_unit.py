import pytest

from pgsupport import checks, report
from pgsupport.checks import CRITICAL, OK, WARNING, Result


@pytest.mark.parametrize("value,expected", [(0, OK), (79.9, OK), (80, WARNING), (94, WARNING), (95, CRITICAL), (100, CRITICAL)])
def test_evaluate_thresholds(value, expected):
    assert checks.evaluate(value, 80, 95) == expected


def test_evaluate_rejects_bad_thresholds():
    with pytest.raises(ValueError):
        checks.evaluate(1, warn=10, crit=5)


def test_worst_picks_highest_and_handles_empty():
    rs = [Result("a", OK, ""), Result("b", CRITICAL, ""), Result("c", WARNING, "")]
    assert checks.worst(rs) == CRITICAL
    assert checks.worst([]) == OK


def test_dns_localhost_ok_and_mismatch_critical():
    assert checks.check_dns("localhost").status == OK
    assert checks.check_dns("localhost", expected_ip="203.0.113.9").status == CRITICAL


def test_dns_unresolvable_is_critical():
    assert checks.check_dns("no-such-host.invalid").status == CRITICAL


def test_report_formats():
    rs = [Result("connections", OK, "5%"), Result("replication", WARNING, "lag 20 МБ")]
    assert "WARNING" in report.as_text(rs)
    assert '"status": "WARNING"' in report.as_json(rs)
    md = report.as_markdown(rs)
    assert "| connections | OK | 5% |" in md and "Итог: WARNING" in md
