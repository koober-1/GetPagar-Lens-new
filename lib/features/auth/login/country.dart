// class Country {
//   const Country({
//     required this.name,
//     required this.flagEmoji,
//     required this.dialCode,
//   });

//   final String name;
//   final String flagEmoji;
//   final String dialCode; // e.g. +91

//   static const india = Country(name: 'India', flagEmoji: '🇮🇳', dialCode: '+91');

//   static const supported = <Country>[
//     india,
//     Country(name: 'United States', flagEmoji: '🇺🇸', dialCode: '+1'),
//     Country(name: 'United Kingdom', flagEmoji: '🇬🇧', dialCode: '+44'),
//     Country(name: 'United Arab Emirates', flagEmoji: '🇦🇪', dialCode: '+971'),
//   ];
// }

class Country {
  const Country({
    required this.name,
    required this.flagEmoji,
    required this.dialCode,
  });

  final String name;
  final String flagEmoji;
  final String dialCode; // e.g. +91

  static const india = Country(
    name: 'India',
    flagEmoji: '🇮🇳',
    dialCode: '+91',
  );

  static const supported = <Country>[
    india,

    Country(name: 'United States', flagEmoji: '🇺🇸', dialCode: '+1'),
    Country(name: 'Canada', flagEmoji: '🇨🇦', dialCode: '+1'),
    Country(name: 'United Kingdom', flagEmoji: '🇬🇧', dialCode: '+44'),
    Country(name: 'Australia', flagEmoji: '🇦🇺', dialCode: '+61'),
    Country(name: 'New Zealand', flagEmoji: '🇳🇿', dialCode: '+64'),
    Country(name: 'United Arab Emirates', flagEmoji: '🇦🇪', dialCode: '+971'),
    Country(name: 'Saudi Arabia', flagEmoji: '🇸🇦', dialCode: '+966'),
    Country(name: 'Singapore', flagEmoji: '🇸🇬', dialCode: '+65'),
    Country(name: 'Malaysia', flagEmoji: '🇲🇾', dialCode: '+60'),
    Country(name: 'Indonesia', flagEmoji: '🇮🇩', dialCode: '+62'),
    Country(name: 'Thailand', flagEmoji: '🇹🇭', dialCode: '+66'),
    Country(name: 'Philippines', flagEmoji: '🇵🇭', dialCode: '+63'),
    Country(name: 'Japan', flagEmoji: '🇯🇵', dialCode: '+81'),
    Country(name: 'South Korea', flagEmoji: '🇰🇷', dialCode: '+82'),
    Country(name: 'China', flagEmoji: '🇨🇳', dialCode: '+86'),
    Country(name: 'Germany', flagEmoji: '🇩🇪', dialCode: '+49'),
    Country(name: 'France', flagEmoji: '🇫🇷', dialCode: '+33'),
    Country(name: 'Italy', flagEmoji: '🇮🇹', dialCode: '+39'),
    Country(name: 'Spain', flagEmoji: '🇪🇸', dialCode: '+34'),
    Country(name: 'Netherlands', flagEmoji: '🇳🇱', dialCode: '+31'),
    Country(name: 'Switzerland', flagEmoji: '🇨🇭', dialCode: '+41'),
    Country(name: 'Brazil', flagEmoji: '🇧🇷', dialCode: '+55'),
    Country(name: 'Mexico', flagEmoji: '🇲🇽', dialCode: '+52'),
    Country(name: 'South Africa', flagEmoji: '🇿🇦', dialCode: '+27'),
    Country(name: 'Nigeria', flagEmoji: '🇳🇬', dialCode: '+234'),
    Country(name: 'Egypt', flagEmoji: '🇪🇬', dialCode: '+20'),
    Country(name: 'Turkey', flagEmoji: '🇹🇷', dialCode: '+90'),
    Country(name: 'Russia', flagEmoji: '🇷🇺', dialCode: '+7'),
  ];
}
