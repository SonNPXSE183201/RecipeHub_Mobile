import { BookOpen, ChevronRight, ClipboardList, MessageSquare } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { recipes, sops } from '@/lib/recipe-data';
import type { NetworkMode } from '@/lib/prototype-state';
import { Empty, NetworkNotice, Notice } from './primitives';

const stepTitles: Record<string, string[]> = {
 'Caramel Latte': ['Syrup & đá', 'Thêm sữa', 'Chiết xuất & rót espresso', 'Kiểm tra & phục vụ'],
 'Matcha Latte': ['Rây matcha', 'Đánh tan matcha', 'Chuẩn bị ly sữa', 'Rót matcha & phục vụ'],
 'Trà đào cam sả': ['Trà & syrup', 'Lắc với đá', 'Thêm trái cây & sả', 'Kiểm tra & phục vụ'],
 'Cappuccino': ['Chiết xuất espresso', 'Đánh sữa', 'Rót sữa', 'Phục vụ nóng'],
 'Latte đá': ['Chuẩn bị đá', 'Thêm sữa', 'Thêm espresso', 'Phục vụ'],
 'Matcha sữa yến mạch': ['Rây matcha', 'Đánh tan matcha', 'Sữa & đá', 'Rót matcha'],
};

export function InstructionDocument({ name, kind, network, onBack, onFeedback, onSop, onPractice, inBook = false }: {
 name?: string | undefined; kind: 'recipe' | 'sop'; network: NetworkMode; onBack: () => void;
 onFeedback: (name: string, step?: number) => void; onSop: (name: string) => void; onPractice: (name: string) => void; inBook?: boolean;
}) {
 const recipe = kind === 'recipe' ? recipes.find(item => item.name === name) : undefined;
 const item = recipe ?? sops.find(item => item.name === name);
 if (!item) return <Empty title="Không mở được tài liệu"><Button onClick={onBack}>Quay lại</Button></Empty>;
 return <div className={`instruction-document ${recipe ? 'recipe-document' : 'sop-document'}`}>
  <div className="document-heading">
   <div><p className="eyebrow">{recipe?.category ?? 'Quy trình vận hành'}</p><h1>{item.name}</h1>
    <div className="document-spec"><span>{recipe ? '1 ly' : `${item.steps.length} bước`}</span><span>{item.time}</span></div>
   </div>
   {recipe && <img src={recipe.image} alt={recipe.name} width={96} height={112}/>}
  </div>
  <NetworkNotice mode={network}/>
  {recipe && <section className="ingredient-section"><div className="section-heading"><h2>Nguyên liệu</h2><span>Cho 1 ly</span></div>
   <div className="ingredients">{recipe.ingredients.map(([label, value]) => {
    const [quantity, ...unit] = value.split(' ');
    return <div className="ingredient" key={label}><span>{label}</span><strong>{quantity}<small>{unit.join(' ')}</small></strong></div>;
   })}</div>
  </section>}
  <section className="method-section"><div className="section-heading"><h2>{recipe ? 'Pha chế' : 'Thực hiện'}</h2><span>{item.steps.length} bước</span></div>
   <ol className="method-list">{item.steps.map((step, index) => <li className="method-step" key={step}>
    <span className="step-number">{index + 1}</span><div><h3>{recipe ? stepTitles[recipe.name]?.[index] ?? `Bước ${index + 1}` : `Bước ${index + 1}`}</h3><p>{step}</p>
     {recipe?.note && index === (recipe.name.includes('Matcha') ? 1 : 2) && <Notice>{recipe.note}</Notice>}
     <Button variant="ghost" size="icon" className="step-feedback" title={`Góp ý bước ${index + 1}`} aria-label={`Góp ý bước ${index + 1}`} onClick={() => onFeedback(item.name, index + 1)}><MessageSquare/></Button>
    </div>
   </li>)}</ol>
  </section>
   {recipe && !inBook && <section className="document-resources"><h2>Tham khảo & thực hành</h2>
   <Button variant="ghost" className="action-row" onClick={() => onPractice(recipe.name)}><BookOpen/><span>Tự luyện món này</span><ChevronRight/></Button>
   {sops.slice(0, 1).map(sop => <Button variant="ghost" className="action-row" key={sop.name} onClick={() => onSop(sop.name)}><ClipboardList/><span>{sop.name}</span><ChevronRight/></Button>)}
   <p className="support-note">Video hướng dẫn: chưa có trong dữ liệu mẫu.</p>
  </section>}
  <details className="metadata"><summary>Thông tin tài liệu</summary><p>Dữ liệu và hình ảnh minh họa, chưa được cửa hàng phê duyệt. Chưa có phiên bản, ngày hoặc người ban hành thật.</p></details>
 </div>;
}