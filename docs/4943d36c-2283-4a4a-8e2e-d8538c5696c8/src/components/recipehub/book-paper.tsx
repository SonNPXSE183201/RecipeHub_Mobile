import { bookEntries } from '@/lib/ebooklet';
import type { PaperBlock, PaperLeaf } from '@/lib/book-pagination';

export function PaperBlockContent({block}:{block:PaperBlock}) {
 if(block.kind==='heading')return <h2 className="leaf-block leaf-heading">{block.text}</h2>;
 if(block.kind==='ingredient')return <table className="leaf-block paper-quantities"><tbody><tr><th scope="row">{block.text}</th><td>{block.quantity}</td></tr></tbody></table>;
 if(block.kind==='step')return <div className="leaf-block leaf-step"><span>{block.number}.</span><p>{block.text}</p></div>;
 if(block.kind==='note')return <aside className="leaf-block leaf-note"><strong>Lưu ý</strong><p>{block.text}</p></aside>;
 return <p className="leaf-block leaf-source">{block.text}</p>;
}
export function PaperHeading({entry: index,continuation=false}:{entry:number;continuation?:boolean}){
 const entry=bookEntries[index];
 return <header className="leaf-heading-context"><p className="paper-edition">{entry?.group??'RecipeHub / Sổ tay'} · {continuation?'Tiếp nối':'Bản mẫu'}</p><h1>{entry?.name??'Khép lại sổ tay'}</h1><p className="paper-description">{entry?`${entry.kind==='recipe'?'Công thức đồ uống':'Quy trình vận hành'} · ${entry.time}`:'Bạn đã đến cuối bộ công thức và quy trình SOP.'}</p></header>;
}
export function BookPaperContent({leaf}:{leaf:PaperLeaf}){
 return <article className="paper-document"><PaperHeading entry={leaf.entry} continuation={leaf.continuation}/>{leaf.blocks.map((block,index)=><PaperBlockContent key={`${block.id}-${index}`} block={block}/>)}</article>;
}
