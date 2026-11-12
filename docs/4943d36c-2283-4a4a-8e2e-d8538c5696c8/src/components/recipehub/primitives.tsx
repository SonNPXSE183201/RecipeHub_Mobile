import { useEffect, useRef, type ReactNode } from 'react';
import { motion, useReducedMotion, useIsPresent } from 'motion/react';
import { ArrowLeft, CircleAlert, LoaderCircle, Search } from 'lucide-react';
import { Button } from '@/components/ui/button';
import type { NetworkMode } from '@/lib/prototype-state';
export function Screen({ title, onBack, children, actions, headerActions, active, sheet = false, hideHeader = false, className = '' }: { title: string; onBack: () => void; children: ReactNode; actions?: ReactNode; headerActions?: ReactNode; active: boolean; sheet?: boolean; hideHeader?: boolean; className?: string }) {
 const ref = useRef<HTMLDivElement>(null);
 const reduced = useReducedMotion();
 const present = useIsPresent();
 const backRef = useRef(onBack);
 backRef.current = onBack;
 useEffect(() => {
  if (!active) return;
  const previous = document.activeElement instanceof HTMLElement ? document.activeElement : null;
  ref.current?.focus({preventScroll:true});
  const key = (e: KeyboardEvent) => { if(e.defaultPrevented)return; if(e.key==='Escape'){e.preventDefault();backRef.current();} if(e.key==='Tab') { const elements=Array.from(ref.current?.querySelectorAll<HTMLElement>('button:not([disabled]), input:not([disabled]):not([hidden]), select:not([disabled]), textarea:not([disabled]), summary, a[href]') ?? []).filter(el=>el.getClientRects().length>0&&!el.closest('[inert]'));const first=elements[0],last=elements.at(-1);if(e.shiftKey && (document.activeElement===first || document.activeElement===ref.current)){e.preventDefault();last?.focus();}else if(!e.shiftKey && document.activeElement===last){e.preventDefault();first?.focus();} } };
  document.addEventListener('keydown',key);return()=>{document.removeEventListener('keydown',key);if(previous?.isConnected)previous.focus({preventScroll:true});};
 },[active]);
 return <motion.div ref={ref} tabIndex={-1} className={`flow-screen ${sheet?'flow-sheet':''} ${className}`} role="dialog" aria-modal={active&&present} aria-label={title} aria-hidden={!active||!present} inert={!active||!present} initial={reduced?{opacity:0}:{opacity:1,...(sheet?{y:'100%'}:{x:'100%'})}} animate={{x:active?0:-18,y:0,opacity:1}} exit={reduced?{opacity:0}:sheet?{y:'100%'}:{x:'100%'}} transition={{duration:reduced?.01:.26,ease:[.2,0,0,1]}} style={{visibility:active?'visible':'hidden'}}>
   {!hideHeader && <header className="flow-header"><Button variant="ghost" size="icon" aria-label={`Quay lại từ ${title}`} onClick={onBack}><ArrowLeft/></Button><strong>{title}</strong>{headerActions ?? <span className="prototype-dot" aria-label="Bản thử nghiệm"/>}</header>}
  <div className="flow-scroll">{children}</div>{actions&&<footer className="flow-actions">{actions}</footer>}
 </motion.div>;
}
export function Notice({ children, error=false }: {children:ReactNode;error?:boolean}) {return <div className={`notice ${error?'notice-error':''}`} role={error?'alert':'status'}><CircleAlert/><div>{children}</div></div>;}
export function Busy({children}: {children:ReactNode}) {return <span className="busy" role="status"><LoaderCircle className="spin"/>{children}</span>;}
export function Empty({title,children}: {title:string;children:ReactNode}) {return <div className="empty-state"><Search/><h2>{title}</h2>{children}</div>;}
export function NetworkNotice({mode}: {mode:NetworkMode}) {return mode==='online'?null:<Notice>{mode==='offline'?'Mô phỏng mất mạng. Bạn vẫn đọc được dữ liệu mẫu; gửi kết quả sẽ cần thử lại.':'Mô phỏng mạng yếu. Kết quả tra cứu chỉ gồm dữ liệu mẫu có sẵn.'}</Notice>;}
