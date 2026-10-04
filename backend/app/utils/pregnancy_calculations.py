from datetime import date, timedelta
from typing import Optional, Tuple


def calculate_edd(lmp: date) -> date:
    """
    Calculates Estimated Due Date (EDD) deterministically from Last Menstrual Period (LMP)
    using the standard 280-day (40 weeks / Naegele's rule) gestation period.
    """
    return lmp + timedelta(days=280)


def calculate_gestational_age(
    lmp: date,
    as_of: Optional[date] = None,
) -> Tuple[int, int, str]:
    """
    Calculates Gestational Age (weeks and remaining days) from LMP.
    Returns: (weeks, days, formatted_display_string)
    Raises: ValueError if LMP is in the future relative to `as_of`.
    """
    if as_of is None:
        as_of = date.today()

    total_days = (as_of - lmp).days
    if total_days < 0:
        raise ValueError("Last Menstrual Period (LMP) cannot be a future date.")

    weeks = total_days // 7
    days = total_days % 7
    display = f"{weeks} weeks {days} days"
    return weeks, days, display


def calculate_trimester(weeks: int) -> Tuple[int, str]:
    """
    Derives the pregnancy trimester from gestational age in weeks.
    - 1st Trimester: Weeks 0 to 12 (< 13)
    - 2nd Trimester: Weeks 13 to 27
    - 3rd Trimester: Weeks 28 and beyond
    """
    if weeks < 13:
        return 1, "1st Trimester"
    elif weeks <= 27:
        return 2, "2nd Trimester"
    else:
        return 3, "3rd Trimester"
