import caramel from '@/assets/caramel-latte.jpg';
import matcha from '@/assets/matcha-latte.jpg';
import tea from '@/assets/peach-tea.jpg';
import cappuccino from '@/assets/cappuccino.jpg';

export const normalize = (value: string) => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();
export type Recipe = { name: string; category: string; time: string; image: string; ingredients: [string, string][]; steps: string[]; note?: string };
export const recipes: Recipe[] = [
 { name: 'Caramel Latte', category: 'Cà phê', time: '3 phút', image: caramel, ingredients: [['Espresso','30 ml'],['Sữa tươi','150 ml'],['Syrup caramel','20 ml'],['Đá viên','180 g']], steps: ['Cho syrup caramel vào ly, thêm đá viên.', 'Rót sữa tươi vào ly, chừa khoảng trống cho espresso.', 'Chiết xuất espresso và rót nhẹ lên trên lớp sữa.', 'Kiểm tra thành phẩm và phục vụ.'], note: 'Chiết xuất espresso ngay trước khi rót để giữ hương vị.' },
 { name: 'Matcha Latte', category: 'Matcha', time: '4 phút', image: matcha, ingredients: [['Bột matcha','3 g'],['Nước ấm','40 ml'],['Sữa tươi','150 ml'],['Syrup đường','15 ml'],['Đá viên','150 g']], steps: ['Rây bột matcha vào chén.', 'Thêm nước ấm và đánh tan bột.', 'Cho đá, syrup đường và sữa vào ly.', 'Rót matcha lên sữa và phục vụ.'], note: 'Dùng nước khoảng 75–80°C; tránh nước sôi.' },
 { name: 'Trà đào cam sả', category: 'Trà trái cây', time: '3 phút', image: tea, ingredients: [['Trà đen','120 ml'],['Syrup đào','25 ml'],['Đào ngâm','2 miếng'],['Cam tươi','1 lát'],['Sả','1 nhánh'],['Đá viên','180 g']], steps: ['Cho trà và syrup đào vào bình lắc.', 'Thêm đá và lắc đều.', 'Rót vào ly, thêm đào, cam và sả.', 'Kiểm tra thành phẩm và phục vụ.'] },
 { name: 'Cappuccino', category: 'Cà phê', time: '4 phút', image: cappuccino, ingredients: [['Espresso','30 ml'],['Sữa tươi','120 ml']], steps: ['Chiết xuất espresso vào tách.', 'Đánh sữa tạo lớp bọt mịn.', 'Rót sữa vào espresso.', 'Phục vụ ngay khi còn nóng.'] },
 { name: 'Latte đá', category: 'Cà phê', time: '3 phút', image: caramel, ingredients: [['Espresso','30 ml'],['Sữa tươi','160 ml'],['Đá viên','180 g']], steps: ['Cho đá vào ly.', 'Rót sữa tươi.', 'Thêm espresso.', 'Phục vụ.'] },
 { name: 'Matcha sữa yến mạch', category: 'Matcha', time: '4 phút', image: matcha, ingredients: [['Bột matcha','3 g'],['Nước ấm','40 ml'],['Sữa yến mạch','150 ml']], steps: ['Rây bột matcha.', 'Đánh tan với nước ấm.', 'Cho sữa và đá vào ly.', 'Rót matcha lên trên.'] },
];
export const filterRecipes = (query: string, category: string, favorites: string[] = []) => recipes.filter(r => normalize(r.name).includes(normalize(query)) && (category === 'Tất cả' || category === 'Đã lưu' && favorites.includes(r.name) || r.category === category));
export const sops = [
 { name: 'Vệ sinh máy espresso', time: '8 phút', steps: ['Ngắt thao tác pha chế và để máy ở trạng thái an toàn.', 'Tháo tay pha, vệ sinh lưới lọc và khay hứng.', 'Vệ sinh đầu group theo hướng dẫn của nhà sản xuất.', 'Lắp lại các bộ phận, kiểm tra trước khi sử dụng.'] },
 { name: 'Chuẩn bị quầy đầu ca', time: '10 phút', steps: ['Kiểm tra vệ sinh bề mặt quầy.', 'Kiểm tra nguyên liệu và hạn sử dụng.', 'Chuẩn bị dụng cụ sạch.', 'Kiểm tra máy và bàn giao trạng thái đầu ca.'] },
 { name: 'Bảo quản nguyên liệu', time: '5 phút', steps: ['Kiểm tra nhãn nguyên liệu.', 'Đậy kín các hộp sau khi sử dụng.', 'Bảo quản theo chỉ dẫn trên bao bì.', 'Ghi nhận nguyên liệu cần bổ sung.'] },
];