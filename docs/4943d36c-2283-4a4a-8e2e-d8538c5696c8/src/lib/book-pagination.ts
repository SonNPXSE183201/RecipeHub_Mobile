import { bookEntries } from './ebooklet';

export type PaperBlock = { id: number; kind: 'heading'|'ingredient'|'step'|'note'|'source'; text: string; quantity?: string; number?: number; offset?: number };
export type PaperLeaf = { entry: number; blocks: PaperBlock[]; continuation: boolean };
export function documentBlocks(entryIndex: number): PaperBlock[] {
 const entry=bookEntries[entryIndex]; if(!entry)return [];
 const blocks: Omit<PaperBlock,'id'>[]=[];
 if(entry.recipe){blocks.push({kind:'heading',text:'Định lượng · 1 ly'});for(const [text,quantity] of entry.recipe.ingredients)blocks.push({kind:'ingredient',text,quantity});}
 if(entry.recipe?.note)blocks.push({kind:'note',text:entry.recipe.note});
 blocks.push({kind:'heading',text:entry.recipe?'Hướng dẫn pha chế':'Hướng dẫn thực hiện'});
 entry.steps.forEach((text,index)=>blocks.push({kind:'step',text,number:index+1}));
 blocks.push({kind:'source',text:'Dữ liệu mẫu chưa được cửa hàng phê duyệt.'});
 return blocks.map((block,id)=>({...block,id}));
}
// Measurements are supplied by the actual browser typography, never guessed character counts.
export function paginateDocument(entry: number, blocks: PaperBlock[], capacity: number, measure: (block: PaperBlock)=>number): PaperLeaf[] {
 const pages: PaperLeaf[]=[];let current:PaperBlock[]=[];let used=0;
 const flush=()=>{if(current.length){pages.push({entry,blocks:current,continuation:pages.length>0});current=[];used=0;}};
 for(let index=0;index<blocks.length;index++){
  const original=blocks[index];if(!original)continue;
  if(original.kind==='heading'){const next=blocks[index+1];if(current.length&&used+measure(original)+(next?Math.min(measure(next),capacity*.35):0)>capacity)flush();}
  let block={...original,offset:0};
  while(true){const height=measure(block);if(used+height<=capacity){current.push(block);used+=height;break;}
   if(height<=capacity || block.kind==='ingredient' || block.kind==='heading'){flush();current.push(block);used=height;break;}
   const words=block.text.split(/\s+/);let low=0,high=words.length;
   while(low<high){const mid=Math.ceil((low+high)/2);if(measure({...block,text:words.slice(0,mid).join(' ')})<=capacity-used)low=mid;else high=mid-1;}
   if(low===0){if(current.length){flush();continue;}throw new Error('Vùng đọc không đủ cho một dòng chữ.');}
   current.push({...block,text:words.slice(0,low).join(' ')});flush();block={...block,text:words.slice(low).join(' '),offset:(block.offset??0)+low};
  }
 }
 flush();return pages;
}
export type GestureDirection = 'pending'|'horizontal'|'dismiss';
export function lockBookGesture(dx:number,dy:number):GestureDirection {if(Math.max(Math.abs(dx),Math.abs(dy))<12)return 'pending';if(Math.abs(dx)>Math.abs(dy)*1.35)return 'horizontal';if(dy>Math.abs(dx)*1.35)return 'dismiss';return 'pending';}
export function shouldDismissBook(dy:number,velocity:number,height:number){return dy>=Math.min(180,height*.24)||(dy>=56&&velocity>=.75);}
