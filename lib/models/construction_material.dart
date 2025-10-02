class ConstructionMaterial {
  final String id;
  final String userId; // Thêm trường userId để phân biệt vật liệu của từng user
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double minStock;
  final double maxStock;
  final double price;
  final String supplier;
  final String description;
  final String? imageUrl;
  final DateTime lastUpdated;
  final List<StockTransaction> transactions;

  ConstructionMaterial({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.price,
    required this.supplier,
    required this.description,
    this.imageUrl,
    required this.lastUpdated,
    this.transactions = const [],
  });

  ConstructionMaterial copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? minStock,
    double? maxStock,
    double? price,
    String? supplier,
    String? description,
    String? imageUrl,
    DateTime? lastUpdated,
    List<StockTransaction>? transactions,
  }) {
    return ConstructionMaterial(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      price: price ?? this.price,
      supplier: supplier ?? this.supplier,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      transactions: transactions ?? this.transactions,
    );
  }

  // Tính toán trạng thái tồn kho
  StockStatus get stockStatus {
    if (currentStock <= minStock) {
      return StockStatus.low;
    } else if (currentStock >= maxStock) {
      return StockStatus.high;
    } else {
      return StockStatus.normal;
    }
  }

  // Tính tổng giá trị tồn kho
  double get totalValue => currentStock * price;
}

class StockTransaction {
  final String id;
  final String materialId;
  final TransactionType type;
  final double quantity;
  final double price;
  final String note;
  final DateTime date;
  final String operator;

  StockTransaction({
    required this.id,
    required this.materialId,
    required this.type,
    required this.quantity,
    required this.price,
    required this.note,
    required this.date,
    required this.operator,
  });
}

enum TransactionType {
  import,  // Nhập kho
  export,  // Xuất kho
  adjust,  // Điều chỉnh
}

enum StockStatus {
  low,     // Tồn kho thấp
  normal,  // Tồn kho bình thường
  high,    // Tồn kho cao
}

// Dữ liệu mẫu
class SampleData {
  static List<ConstructionMaterial> get materials => [
    ConstructionMaterial(
      id: '1',
      userId: 'sample_user_1', // Thêm userId cho dữ liệu mẫu
      name: 'Xi măng PCB40',
      category: 'Vật liệu kết dính',
      unit: 'Bao',
      currentStock: 150,
      minStock: 50,
      maxStock: 300,
      price: 85000,
      supplier: 'Công ty Xi măng Hà Tiên',
      description: 'Xi măng Portland PCB40 chất lượng cao',
      imageUrl: 'https://picsum.photos/200/200?random=1',
      lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
      transactions: [
        StockTransaction(
          id: 't1',
          materialId: '1',
          type: TransactionType.import,
          quantity: 100,
          price: 85000,
          note: 'Nhập kho đầu tháng',
          date: DateTime.now().subtract(const Duration(days: 2)),
          operator: 'Nguyễn Văn A',
        ),
        StockTransaction(
          id: 't2',
          materialId: '1',
          type: TransactionType.export,
          quantity: 50,
          price: 85000,
          note: 'Xuất cho dự án A',
          date: DateTime.now().subtract(const Duration(days: 1)),
          operator: 'Trần Thị B',
        ),
      ],
    ),
    ConstructionMaterial(
      id: '2',
      userId: 'sample_user_1',
      name: 'Cát xây dựng',
      category: 'Vật liệu cốt liệu',
      unit: 'm³',
      currentStock: 25.5,
      minStock: 10,
      maxStock: 50,
      price: 180000,
      supplier: 'Công ty Cát sông Hồng',
      description: 'Cát vàng chất lượng tốt cho xây dựng',
      imageUrl: 'https://picsum.photos/200/200?random=2',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ConstructionMaterial(
      id: '3',
      userId: 'sample_user_1',
      name: 'Gạch đỏ 4 lỗ',
      category: 'Vật liệu xây',
      unit: 'Viên',
      currentStock: 5000,
      minStock: 1000,
      maxStock: 10000,
      price: 2500,
      supplier: 'Nhà máy gạch Đồng Nai',
      description: 'Gạch đỏ 4 lỗ chuẩn kích thước 10x20x5cm',
      imageUrl: 'https://picsum.photos/200/200?random=3',
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ConstructionMaterial(
      id: '4',
      userId: 'sample_user_1',
      name: 'Thép D16',
      category: 'Vật liệu cốt thép',
      unit: 'Cây',
      currentStock: 45,
      minStock: 20,
      maxStock: 100,
      price: 185000,
      supplier: 'Công ty Thép Việt Nam',
      description: 'Thép cốt bê tông D16, dài 11.7m',
      imageUrl: 'https://picsum.photos/200/200?random=4',
      lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ConstructionMaterial(
      id: '5',
      userId: 'sample_user_1',
      name: 'Đá 1x2',
      category: 'Vật liệu cốt liệu',
      unit: 'm³',
      currentStock: 15,
      minStock: 5,
      maxStock: 30,
      price: 220000,
      supplier: 'Mỏ đá Bình Dương',
      description: 'Đá dăm 1x2 cho bê tông',
      imageUrl: 'https://picsum.photos/200/200?random=5',
      lastUpdated: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];
}
