from decimal import Decimal

from app.models.product import UnitType


def weight_grams_for(unit_type: UnitType | str, weight_grams: int | None, qty: Decimal) -> Decimal:
    """Total weight in grams for `qty` units of a product. For a KG
    product the quantity already *is* the weight (qty 12 means 12 kg) —
    weight_grams is irrelevant there. For a PCS product, weight_grams is
    the weight of one piece; with none set, the product simply doesn't
    contribute to weight totals yet (not an error)."""
    unit = unit_type.value if hasattr(unit_type, "value") else unit_type
    if unit == UnitType.KG.value:
        return qty * Decimal(1000)
    if weight_grams is None:
        return Decimal(0)
    return Decimal(weight_grams) * qty
