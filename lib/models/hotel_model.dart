class Hotel {
  final String id;
  final String name;
  final String location;
  final double rating;
  final int reviewCount;
  final double pricePerNight;
  final String imageUrl;
  final String description;
  final List<String> amenities;

  Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNight,
    required this.imageUrl,
    required this.description,
    required this.amenities,
  });
}

// Updated mock data with Indian hotels
List<Hotel> mockHotels = [
  Hotel(
    id: '1',
    name: 'Taj Mahal Palace',
    location: 'Mumbai, India',
    rating: 4.8,
    reviewCount: 2845,
    pricePerNight: 8999,
    imageUrl: 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=400',
    description: 'Iconic luxury hotel overlooking the Gateway of India and Arabian Sea. Experience royal treatment and world-class amenities.',
    amenities: ['Free WiFi', 'Swimming Pool', 'Luxury Spa', 'Fine Dining', '24/7 Service'],
  ),
  Hotel(
    id: '2',
    name: 'ITC Grand Chola',
    location: 'Chennai, India',
    rating: 4.7,
    reviewCount: 1923,
    pricePerNight: 7599,
    imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400',
    description: 'Luxurious 5-star hotel with traditional South Indian architecture and modern comforts.',
    amenities: ['Pool', 'Business Center', 'Multiple Restaurants', 'Spa', 'Gym'],
  ),
  Hotel(
    id: '3',
    name: 'Leela Palace',
    location: 'New Delhi, India',
    rating: 4.6,
    reviewCount: 1567,
    pricePerNight: 6899,
    imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400',
    description: 'Regal hotel offering elegant rooms and exceptional service in the heart of the capital city.',
    amenities: ['Free WiFi', 'Pool', 'Yoga Center', 'Luxury Spa', 'Fine Dining'],
  ),
  Hotel(
    id: '4',
    name: 'Goa Marriott Resort',
    location: 'Goa, India',
    rating: 4.5,
    reviewCount: 987,
    pricePerNight: 5499,
    imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400',
    description: 'Beachfront resort with private beach access and stunning Arabian Sea views.',
    amenities: ['Beach Access', 'Pool', 'Water Sports', 'Spa', 'Kids Club'],
  ),
  Hotel(
    id: '5',
    name: 'Budget Stay Inn',
    location: 'Bangalore, India',
    rating: 4.2,
    reviewCount: 456,
    pricePerNight: 2499,
    imageUrl: 'https://images.unsplash.com/photo-1586375300773-8384e3e4916f?w=400',
    description: 'Comfortable and affordable accommodation with all essential amenities for business travelers.',
    amenities: ['Free WiFi', 'Breakfast', 'Airport Transfer', '24/7 Front Desk'],
  ),
];