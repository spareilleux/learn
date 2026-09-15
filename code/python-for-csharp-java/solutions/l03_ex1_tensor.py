# solutions/l03_ex1_tensor.py
from collections import Counter


def tensor_summary(beliefs: list[dict[str, str]]) -> dict[str, object]:
    # A Counter counts in one pass, and returns 0 for a key it has never seen
    distribution = Counter(belief.get("tensorConfig", "U_U") for belief in beliefs)
    return {
        "total_beliefs": len(beliefs),
        "tensor_distribution": dict(distribution),
        "wisdom_count": distribution["C_T"],
        "hunch_count": distribution["T_C"],
        "blindspot_count": distribution["U_F"],
    }


if __name__ == "__main__":
    beliefs = [{"tensorConfig": "C_T"}, {"tensorConfig": "T_C"}, {}, {"tensorConfig": "C_T"}]
    print(tensor_summary(beliefs))
