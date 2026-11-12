import { describe,it,expect } from 'vitest';
import { documentBlocks,paginateDocument,lockBookGesture,shouldDismissBook } from '@/lib/book-pagination';
import { bookEntries } from '@/lib/ebooklet';
describe('gesture-only paginated book',()=>{
 it('preserves every recipe and SOP block across small pages',()=>{for(let entry=0;entry<bookEntries.length;entry++){const blocks=documentBlocks(entry);const leaves=paginateDocument(entry,blocks,160,b=>20+b.text.split(/\s+/).length*4);for(const original of blocks){const pieces=leaves.flatMap(p=>p.blocks).filter(b=>b.id===original.id);expect(pieces.map(b=>b.text).join(' ')).toBe(original.text);if(original.kind==='ingredient')expect(pieces).toHaveLength(1);}expect(leaves.slice(1).every(p=>p.continuation)).toBe(true);}});
 it('reflows into more leaves when the reading area shrinks',()=>{const blocks=documentBlocks(0),measure=(b:{text:string})=>30+b.text.length;expect(paginateDocument(0,blocks,180,measure).length).toBeGreaterThan(paginateDocument(0,blocks,400,measure).length);});
 it('locks horizontal turns separately from downward dismissal',()=>{expect(lockBookGesture(-72,8)).toBe('horizontal');expect(lockBookGesture(8,72)).toBe('dismiss');expect(lockBookGesture(0,4)).toBe('pending');expect(lockBookGesture(0,-80)).toBe('pending');});
 it('cancels short pulls and accepts long or fast downward swipes',()=>{expect(shouldDismissBook(40,.2,800)).toBe(false);expect(shouldDismissBook(180,.2,800)).toBe(true);expect(shouldDismissBook(60,.8,800)).toBe(true);});
});
