import 'package:flutter/material.dart';

/// A country a user can pick for regional updates. [code] is the ISO 3166-1
/// alpha-2 code stored in `profiles.country_code` and used for the
/// `country_<CODE>` notification topic.
class SupportedCountry {
  const SupportedCountry(this.code, this.name);

  final String code;
  final String name;
}

const supportedCountries = <SupportedCountry>[
  SupportedCountry('IN', 'India'),
  SupportedCountry('US', 'United States'),
  SupportedCountry('GB', 'United Kingdom'),
  SupportedCountry('CA', 'Canada'),
  SupportedCountry('AU', 'Australia'),
  // Gulf Cooperation Council
  SupportedCountry('AE', 'United Arab Emirates'),
  SupportedCountry('SA', 'Saudi Arabia'),
  SupportedCountry('QA', 'Qatar'),
  SupportedCountry('KW', 'Kuwait'),
  SupportedCountry('BH', 'Bahrain'),
  SupportedCountry('OM', 'Oman'),
];

List<DropdownMenuItem<String>> countryDropdownItems() => [
  for (final country in supportedCountries)
    DropdownMenuItem(value: country.code, child: Text(country.name)),
];
