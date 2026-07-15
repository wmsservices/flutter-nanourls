// Espelha NanoUrls.Domain.Helpers.PlanHelper (dotnet) para detectar downgrade no cliente.
// Tiers por planId: 1=Free, 2/3=Pro (mensal/anual), 4/5=Max (mensal/anual).
class PlanHelper {
  static int _tierOf(int planId) {
    switch (planId) {
      case 2:
      case 3:
        return 1;
      case 4:
      case 5:
        return 2;
      default:
        return 0;
    }
  }

  static bool isPlanDowngrading(int migratePlanId, int actualPlanId) {
    return _tierOf(migratePlanId) < _tierOf(actualPlanId);
  }
}
