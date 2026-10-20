import 'dart:math';
import 'package:flutter/material.dart';
import '../data/drivermodel.dart';

class DriverFilterService {
  static final DriverFilterService _instance = DriverFilterService._internal();
  factory DriverFilterService() => _instance;
  DriverFilterService._internal();

  // Filter criteria
  double _minRating = 0.0;
  double _maxRating = 5.0;
  double _minPrice = 0.0;
  double _maxPrice = double.infinity;
  bool _onlineOnly = false;
  int _minExperience = 0;
  String _searchQuery = '';
  String _sortBy = 'rating'; // rating, price, experience, name

  // Getters
  double get minRating => _minRating;
  double get maxRating => _maxRating;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  bool get onlineOnly => _onlineOnly;
  int get minExperience => _minExperience;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  // Setters
  void setRatingRange(double min, double max) {
    _minRating = min;
    _maxRating = max;
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
  }

  void setOnlineOnly(bool value) {
    _onlineOnly = value;
  }

  void setMinExperience(int value) {
    _minExperience = value;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
  }

  void setSortBy(String criteria) {
    _sortBy = criteria;
  }

  // Reset all filters
  void resetFilters() {
    _minRating = 0.0;
    _maxRating = 5.0;
    _minPrice = 0.0;
    _maxPrice = double.infinity;
    _onlineOnly = false;
    _minExperience = 0;
    _searchQuery = '';
    _sortBy = 'rating';
  }

  // Filter drivers based on criteria
  List<UserModel> filterDrivers(List<UserModel> drivers) {
    List<UserModel> filtered = List.from(drivers);

    // Filter by online status
    if (_onlineOnly) {
      filtered = filtered.where((driver) => driver.isOnline).toList();
    }

    // Filter by rating
    filtered = filtered.where((driver) {
      final rating = driver.rating ?? 0.0;
      return rating >= _minRating && rating <= _maxRating;
    }).toList();

    // Filter by price
    filtered = filtered.where((driver) {
      final price = driver.price ?? 0.0;
      return price >= _minPrice && price <= _maxPrice;
    }).toList();

    // Filter by experience
    filtered = filtered.where((driver) {
      final experience = driver.experience ?? 0;
      return experience >= _minExperience;
    }).toList();

    // Filter by search query (name, phone, driver type)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((driver) {
        final name = (driver.name ?? '').toLowerCase();
        final phone = (driver.phone ?? '').toLowerCase();
        final driverType = (driver.driver ?? '').toLowerCase();
        
        return name.contains(_searchQuery) ||
               phone.contains(_searchQuery) ||
               driverType.contains(_searchQuery);
      }).toList();
    }

    // Sort results
    filtered = _sortDrivers(filtered);

    return filtered;
  }

  // Sort drivers based on criteria
  List<UserModel> _sortDrivers(List<UserModel> drivers) {
    switch (_sortBy) {
      case 'rating':
        drivers.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
        break;
      case 'price':
        drivers.sort((a, b) => (a.price ?? 0.0).compareTo(b.price ?? 0.0));
        break;
      case 'experience':
        drivers.sort((a, b) => (b.experience ?? 0).compareTo(a.experience ?? 0));
        break;
      case 'name':
        drivers.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
    }
    return drivers;
  }

  // Get filter summary
  String getFilterSummary() {
    List<String> filters = [];
    
    if (_onlineOnly) filters.add('Online only');
    if (_minRating > 0.0) filters.add('Rating ≥ $_minRating');
    if (_maxRating < 5.0) filters.add('Rating ≤ $_maxRating');
    if (_minPrice > 0.0) filters.add('Price ≥ ₹$_minPrice');
    if (_maxPrice < double.infinity) filters.add('Price ≤ ₹$_maxPrice');
    if (_minExperience > 0) filters.add('Experience ≥ $_minExperience years');
    if (_searchQuery.isNotEmpty) filters.add('Search: "$_searchQuery"');
    
    return filters.isEmpty ? 'No filters applied' : filters.join(' • ');
  }

  // Get active filters count
  int getActiveFiltersCount() {
    int count = 0;
    if (_onlineOnly) count++;
    if (_minRating > 0.0) count++;
    if (_maxRating < 5.0) count++;
    if (_minPrice > 0.0) count++;
    if (_maxPrice < double.infinity) count++;
    if (_minExperience > 0) count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }
}

// Driver filter widget
class DriverFilterWidget extends StatefulWidget {
  final List<UserModel> drivers;
  final Function(List<UserModel>) onFilteredDrivers;

  const DriverFilterWidget({
    Key? key,
    required this.drivers,
    required this.onFilteredDrivers,
  }) : super(key: key);

  @override
  State<DriverFilterWidget> createState() => _DriverFilterWidgetState();
}

class _DriverFilterWidgetState extends State<DriverFilterWidget> {
  final DriverFilterService _filterService = DriverFilterService();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Don't call setState during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  void _applyFilters() {
    final filtered = _filterService.filterDrivers(widget.drivers);
    widget.onFilteredDrivers(filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Filter header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _filterService.getFilterSummary(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (_filterService.getActiveFiltersCount() > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_filterService.getActiveFiltersCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  child: Text(_showFilters ? 'Hide' : 'Show'),
                ),
                IconButton(
                  onPressed: () {
                    _filterService.resetFilters();
                    _applyFilters();
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset Filters',
                ),
              ],
            ),
          ),
          
          // Filter controls
          if (_showFilters) _buildFilterControls(),
          
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Drivers',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _filterService.setSearchQuery(value);
              _applyFilters();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Rating range
          Text('Rating Range: ${_filterService.minRating.toStringAsFixed(1)} - ${_filterService.maxRating.toStringAsFixed(1)}'),
          RangeSlider(
            values: RangeValues(_filterService.minRating, _filterService.maxRating),
            min: 0.0,
            max: 5.0,
            divisions: 10,
            onChanged: (values) {
              _filterService.setRatingRange(values.start, values.end);
              _applyFilters();
              setState(() {});
            },
          ),
          
          const SizedBox(height: 16),
          
          // Price range
          Text('Price Range: ₹${_filterService.minPrice.toStringAsFixed(0)} - ${_filterService.maxPrice == double.infinity ? '∞' : _filterService.maxPrice.toStringAsFixed(0)}'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? 0.0;
                    _filterService.setPriceRange(price, _filterService.maxPrice);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? double.infinity;
                    _filterService.setPriceRange(_filterService.minPrice, price);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Experience
          TextField(
            decoration: const InputDecoration(
              labelText: 'Minimum Experience (years)',
              prefixIcon: Icon(Icons.work),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final experience = int.tryParse(value) ?? 0;
              _filterService.setMinExperience(experience);
              _applyFilters();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Online only and sort
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Online Only'),
                  value: _filterService.onlineOnly,
                  onChanged: (value) {
                    _filterService.setOnlineOnly(value ?? false);
                    _applyFilters();
                    setState(() {});
                  },
                  dense: true,
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                  ),
                  value: _filterService.sortBy,
                  items: const [
                    DropdownMenuItem(value: 'rating', child: Text('Rating')),
                    DropdownMenuItem(value: 'price', child: Text('Price')),
                    DropdownMenuItem(value: 'experience', child: Text('Experience')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _filterService.setSortBy(value);
                      _applyFilters();
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
