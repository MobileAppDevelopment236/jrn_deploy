class Country {
  final String name;
  final String code;
  final String dialCode;

  const Country({required this.name, required this.code, required this.dialCode});

  @override
  String toString() => name;
}

class CountryUtils {
  static final List<Country> countries = [
    const Country(name: 'United States', code: 'US', dialCode: '+1'),
    const Country(name: 'Canada', code: 'CA', dialCode: '+1'),
    const Country(name: 'United Kingdom', code: 'GB', dialCode: '+44'),
    const Country(name: 'Australia', code: 'AU', dialCode: '+61'),
    const Country(name: 'Germany', code: 'DE', dialCode: '+49'),
    const Country(name: 'France', code: 'FR', dialCode: '+33'),
    const Country(name: 'India', code: 'IN', dialCode: '+91'),
    const Country(name: 'Japan', code: 'JP', dialCode: '+81'),
    const Country(name: 'China', code: 'CN', dialCode: '+86'),
    const Country(name: 'Brazil', code: 'BR', dialCode: '+55'),
  ];

  static List<String> get countryNames => countries.map((c) => c.name).toList();

  static Country getCountryByName(String name) {
    return countries.firstWhere((c) => c.name == name, 
      orElse: () => countries.first);
  }
}