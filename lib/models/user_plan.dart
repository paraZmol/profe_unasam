enum UserPlan { free, trial, premium }

extension UserPlanLabel on UserPlan {
  String get label {
    switch (this) {
      case UserPlan.free:
        return 'Básico';
      case UserPlan.trial:
        return 'Prueba';
      case UserPlan.premium:
        return 'Premium';
    }
  }
}
