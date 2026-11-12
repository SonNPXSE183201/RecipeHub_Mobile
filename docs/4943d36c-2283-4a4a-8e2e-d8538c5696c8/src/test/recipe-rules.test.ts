import { describe, it, expect } from 'vitest';
import { filterRecipes, normalize } from '@/lib/recipe-data';
describe('RecipeHub lookup rules', () => {
 it('finds Vietnamese names without accents', () => { expect(filterRecipes('tra dao', 'Tất cả').map(r=>r.name)).toEqual(['Trà đào cam sả']); });
 it('normalizes crossed d',()=>{expect(normalize('Đá')).toBe('da');});
 it('keeps category filtering active while searching',()=>{expect(filterRecipes('latte','Matcha').map(r=>r.name)).toEqual(['Matcha Latte']);});
 it('only shows explicitly saved recipes',()=>{expect(filterRecipes('','Đã lưu',['Caramel Latte']).map(r=>r.name)).toEqual(['Caramel Latte']);});
});
