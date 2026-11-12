import { useLayoutEffect, useRef, useState, type Dispatch, type SetStateAction } from 'react';
import { animate, motion, useMotionValue } from 'motion/react';
import { BookPaperContent, PaperBlockContent, PaperHeading } from './book-paper';
import { bookEntries, pageTurnDuration, swipePageDelta, type ReadingPosition } from '@/lib/ebooklet';
import { documentBlocks, paginateDocument, lockBookGesture, shouldDismissBook, type PaperLeaf, type PaperBlock, type GestureDirection } from '@/lib/book-pagination';

type Turn={from:number;to:number;direction:number;id:number};
export function BookReader({position,setPosition,reduced,onClose,active=true}:{position:ReadingPosition;setPosition:Dispatch<SetStateAction<ReadingPosition>>;reduced:boolean;onClose:()=>void;active?:boolean}){
 const stage=useRef<HTMLDivElement>(null), measureRoot=useRef<HTMLDivElement>(null);
 const [leaves,setLeaves]=useState<PaperLeaf[]>([]);const [index,setIndex]=useState(0);const [turn,setTurn]=useState<Turn|null>(null);const turning=useRef(false);const closing=useRef(false);const serial=useRef(0);
 const anchor=useRef(position);anchor.current=position;
 const pointer=useRef<{x:number;y:number;dx:number;time:number;direction:GestureDirection}|null>(null);
 const y=useMotionValue(0),scale=useMotionValue(1),angle=useMotionValue(0);
 const allBlocks=bookEntries.map((_,i)=>documentBlocks(i));
 useLayoutEffect(()=>{
  const el=stage.current,root=measureRoot.current;if(!el||!root||!active)return;
  const recalculate=()=>{
   const computed=getComputedStyle(el);const available=el.clientHeight-parseFloat(computed.paddingTop)-parseFloat(computed.paddingBottom)-28;
   const measured:PaperLeaf[]=[];
   for(let entry=0;entry<bookEntries.length;entry++){
   const header=root.querySelector<HTMLElement>(`[data-header="${entry}"]`);const capacity=available-(header?.offsetHeight??0)-8;
    const measure=(block:PaperBlock)=>{const source=root.querySelector<HTMLElement>(`[data-entry="${entry}"][data-block="${block.id}"] > *`);if(!source)return 0;const clone=source.cloneNode(true) as HTMLElement;const paragraph=clone.querySelector('p');if(paragraph)paragraph.textContent=block.text;else if(block.kind!=='ingredient')clone.textContent=block.text;root.appendChild(clone);const height=clone.offsetHeight;clone.remove();return height;};
    measured.push(...paginateDocument(entry,documentBlocks(entry),Math.max(80,capacity),measure));
   }
   measured.push({entry:bookEntries.length,continuation:false,blocks:[{id:0,kind:'source',text:`${bookEntries.filter(e=>e.kind==='recipe').length} công thức · ${bookEntries.filter(e=>e.kind==='sop').length} SOP. Dữ liệu mẫu chưa được cửa hàng phê duyệt.`}]});
   const saved=anchor.current;let destination=measured.findIndex(leaf=>leaf.entry===saved.page&&leaf.blocks.some(b=>b.id===(saved.block??0)&&(b.offset??0)<=(saved.offset??0)&&((b.offset??0)+b.text.split(/\s+/).length)>(saved.offset??0)));
   if(destination<0)destination=Math.max(0,measured.findIndex(leaf=>leaf.entry===saved.page));
   turning.current=false;setTurn(null);setLeaves(measured);setIndex(destination);
  };
  recalculate();el.focus({preventScroll:true});const observer=new ResizeObserver(recalculate);observer.observe(el);const textObserver=new MutationObserver(recalculate);const app=el.closest('.mobile-app');if(app)textObserver.observe(app,{attributes:true,attributeFilter:['class','style']});textObserver.observe(document.documentElement,{attributes:true,attributeFilter:['class','style']});document.fonts.ready.then(recalculate);document.fonts.addEventListener('loadingdone',recalculate);return()=>{observer.disconnect();textObserver.disconnect();document.fonts.removeEventListener('loadingdone',recalculate);};
 },[active]);
 const save=(next:number)=>{const leaf=leaves[next];if(!leaf)return;const block=leaf.blocks[0];setPosition(p=>({...p,started:true,page:leaf.entry,block:block?.id??0,offset:block?.offset??0}));};
 const move=(delta:number)=>{if(turning.current||closing.current)return;const target=Math.max(0,Math.min(leaves.length-1,index+delta));if(target===index)return;save(target);setIndex(target);if(!reduced){turning.current=true;setTurn({from:index,to:target,direction:delta,id:++serial.current});}};
 const close=async()=>{if(closing.current)return;closing.current=true;save(index);if(!reduced)await animate(y,stage.current?.clientHeight??900,{duration:.24,ease:[.2,0,0,1]});onClose();};
 const release=(cancel=false)=>{const start=pointer.current;pointer.current=null;if(!start)return;const dy=y.get();if(!cancel&&start.direction==='dismiss'&&shouldDismissBook(dy,dy/Math.max(1,performance.now()-start.time),stage.current?.clientHeight??800)){void close();return;}if(!cancel&&start.direction==='horizontal'){const delta=swipePageDelta(start.dx,0);if(delta)move(delta);}animate(y,0,{duration:reduced?0:.18});animate(scale,1,{duration:reduced?0:.18});animate(angle,0,{duration:reduced?0:.16});};
 const leaf=leaves[turn&&turn.direction<0?turn.from:index];
 return <motion.div ref={stage} className="book-stage gesture-book" role="document" aria-label="Nội dung sổ tay" tabIndex={0} data-leaf={index} data-pages={leaves.length} data-turning={Boolean(turn)} style={{y,scale}}
  onKeyDown={e=>{if(e.key==='ArrowRight'){e.preventDefault();move(1);}if(e.key==='ArrowLeft'){e.preventDefault();move(-1);}if(e.key==='Escape'){e.preventDefault();void close();}}}
  onPointerDown={e=>{if(closing.current||turning.current)return;e.currentTarget.setPointerCapture(e.pointerId);pointer.current={x:e.clientX,y:e.clientY,dx:0,time:performance.now(),direction:'pending'};}}
  onPointerMove={e=>{const start=pointer.current;if(!start)return;const dx=e.clientX-start.x,dy=e.clientY-start.y;start.dx=dx;if(start.direction==='pending')start.direction=lockBookGesture(dx,dy);if(start.direction==='dismiss'){y.set(Math.max(0,dy));scale.set(reduced?1:1-Math.min(.05,Math.max(0,dy)/6000));}else if(start.direction==='horizontal'&&((dx<0&&index<leaves.length-1)||(dx>0&&index>0)))angle.set(Math.max(-35,Math.min(35,dx/10)));}}
  onPointerUp={()=>release()} onPointerCancel={()=>release(true)}>
  <div ref={measureRoot} className="paper-measure" aria-hidden="true" inert>{allBlocks.map((blocks,entry)=><div key={entry}><div data-header={entry}><PaperHeading entry={entry} continuation/></div>{blocks.map(block=><div key={block.id} data-entry={entry} data-block={block.id}><PaperBlockContent block={block}/></div>)}</div>)}</div>
  <motion.div className="paper-page paper-base" style={{rotateY:reduced?0:angle}}>{leaf&&<BookPaperContent leaf={leaf}/>}<span className="printed-folio">{index+1}</span></motion.div>
  {turn&&!reduced&&<motion.div key={turn.id} className="paper-page paper-turn" aria-hidden="true" inert initial={{rotateY:turn.direction>0?0:-180}} animate={{rotateY:turn.direction>0?-180:0}} transition={{duration:pageTurnDuration,ease:[.32,.05,.2,1]}} onAnimationComplete={()=>{turning.current=false;setTurn(null);}}><div className="paper-face paper-front">{leaves[turn.direction>0?turn.from:turn.to]&&<BookPaperContent leaf={leaves[turn.direction>0?turn.from:turn.to] as PaperLeaf}/>}<span className="printed-folio">{(turn.direction>0?turn.from:turn.to)+1}</span><div className="paper-light"/></div><div className="paper-face paper-back"><span className="paper-back-mark">RecipeHub</span></div></motion.div>}
 </motion.div>;
}
