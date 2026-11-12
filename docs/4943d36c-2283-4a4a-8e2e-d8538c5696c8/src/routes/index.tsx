import { createFileRoute } from '@tanstack/react-router';
import { RecipeHubApp } from '@/components/recipehub/app';
export const Route = createFileRoute('/')({
 head:()=>({meta:[{title:'RecipeHub — Sổ tay pha chế & đào tạo'},{name:'description',content:'Bản tham chiếu mobile RecipeHub: công thức, SOP, việc học, tự luyện và phản hồi liên kết xuyên suốt.'},{property:'og:title',content:'RecipeHub — Sổ tay pha chế & đào tạo'},{property:'og:description',content:'Tra cứu tại quầy, học và tự luyện trong trải nghiệm mobile RecipeHub.'},{property:'og:type',content:'website'},{name:'twitter:card',content:'summary_large_image'}]}),
 component:RecipeHubApp,
});
