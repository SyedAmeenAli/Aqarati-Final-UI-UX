enum CalculatorType {
  emi,
  affordability,
  downPayment,
  rentalYield,
  roi,
  rentVsBuy,
  appreciation,
  constructionCost,
}

extension CalculatorTypeInfo on CalculatorType {
  String get title {
    switch (this) {
      case CalculatorType.emi:
        return 'EMI Calculator';
      case CalculatorType.affordability:
        return 'Affordability';
      case CalculatorType.downPayment:
        return 'Down Payment';
      case CalculatorType.rentalYield:
        return 'Rental Yield';
      case CalculatorType.roi:
        return 'ROI';
      case CalculatorType.rentVsBuy:
        return 'Rent vs Buy';
      case CalculatorType.appreciation:
        return 'Property Appreciation';
      case CalculatorType.constructionCost:
        return 'Construction Cost';
    }
  }

  String get description {
    switch (this) {
      case CalculatorType.emi:
        return 'Estimate your monthly loan payment.';
      case CalculatorType.affordability:
        return 'See what property price fits your budget.';
      case CalculatorType.downPayment:
        return 'Work out how much you need upfront.';
      case CalculatorType.rentalYield:
        return 'Check the annual return on a rental property.';
      case CalculatorType.roi:
        return 'Estimate return on investment over time.';
      case CalculatorType.rentVsBuy:
        return 'Compare renting against buying.';
      case CalculatorType.appreciation:
        return 'Project future property value.';
      case CalculatorType.constructionCost:
        return 'Estimate a build cost from area and rate.';
    }
  }
}
