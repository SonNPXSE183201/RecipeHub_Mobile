import { bookEntries, completeBook, type BookEntry } from './ebooklet';
import readingFont from '@/assets/reading-font-static.asset.json';

export async function createBookPdf(entries: BookEntry[] = bookEntries) {
 if (!completeBook(entries)) throw new Error('Sổ tay chưa tải đủ công thức và SOP.');
 const [{ jsPDF }, response] = await Promise.all([import('jspdf'), fetch(readingFont.url)]);
 if (!response.ok) throw new Error('Không tải được phông chữ tiếng Việt.');
 const bytes = new Uint8Array(await response.arrayBuffer());
 let binary = '';
 for (let i = 0; i < bytes.length; i += 8192) binary += String.fromCharCode(...bytes.subarray(i, i + 8192));
 const pdf = new jsPDF();
 pdf.addFileToVFS('RecipeHub.ttf', btoa(binary));
 pdf.addFont('RecipeHub.ttf', 'RecipeHub', 'normal');
 pdf.setFont('RecipeHub');
 pdf.setProperties({ title: 'RecipeHub — Sổ tay công thức & SOP', subject: 'Dữ liệu mẫu của bản tham chiếu UX' });
 let y = 24;
 const line = (text: string, size = 11) => {
  pdf.setFontSize(size);
  const lines: string[] = pdf.splitTextToSize(text, 170);
  for (const part of lines) { if (y > 270) { pdf.addPage(); y = 24; } pdf.text(part, 20, y); y += size * .52; }
  y += 4;
 };
 line('RecipeHub', 26); line('Sổ tay công thức & SOP', 21);
 line(`${entries.filter(e => e.kind === 'recipe').length} công thức · ${entries.filter(e => e.kind === 'sop').length} quy trình SOP`);
 line('Dữ liệu mẫu, chưa được cửa hàng phê duyệt. Không phải tài liệu vận hành chính thức.');
 line('Mục lục', 16);
 entries.forEach((entry, index) => line(`${index + 1}. ${entry.name} · ${entry.kind === 'sop' ? 'SOP' : entry.group}`));
 for (const entry of entries) {
  pdf.addPage(); y = 24;
  line(entry.group, 11); line(entry.name, 20); line(`${entry.recipe ? '1 ly · ' : ''}${entry.time}`);
  if (entry.recipe) { line('Nguyên liệu · Cho 1 ly', 15); entry.recipe.ingredients.forEach(([name, amount]) => line(`${name}: ${amount}`)); }
  line(entry.kind === 'recipe' ? 'Pha chế' : 'Thực hiện', 15);
  entry.steps.forEach((step, index) => line(`${index + 1}. ${step}`));
  if (entry.recipe?.note) { line('Lưu ý', 15); line(entry.recipe.note); }
 }
 const pages = pdf.getNumberOfPages();
 for (let i = 1; i <= pages; i++) { pdf.setPage(i); pdf.setFontSize(9); pdf.text(`RecipeHub · ${i}/${pages}`, 20, 287); }
 return { blob: pdf.output('blob'), pages };
}