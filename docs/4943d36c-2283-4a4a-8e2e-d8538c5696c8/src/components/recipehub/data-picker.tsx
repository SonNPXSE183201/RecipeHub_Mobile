import { useEffect, useId, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { ChevronDown } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Busy, Notice } from './primitives';

type Option = { value: string; label: string };
type Props = {
 id: string; title: string; value: string; options: Option[]; onChange: (value: string) => void;
  placeholder?: string; disabled?: boolean; invalid?: boolean;
 status?: 'ready' | 'loading' | 'error'; onRetry?: () => void;
 onOpen: (dismiss: () => void) => void; onClose: () => void;
};

export function DataPicker({ id, title, value, options, onChange, placeholder = 'Chọn một giá trị', disabled, invalid, status = 'ready', onRetry, onOpen, onClose }: Props) {
 const [open, setOpen] = useState(false);
 const [large, setLarge] = useState(false);
 const [reduceSetting, setReduceSetting] = useState(false);
 const reduced = useReducedMotion();
 const trigger = useRef<HTMLButtonElement>(null);
 const dialog = useRef<HTMLDivElement>(null);
 const closeRef = useRef(() => {});
 const titleId = useId();
 const close = () => { setOpen(false); onClose(); };
 closeRef.current = close;
 useEffect(() => {
  if (!open) return;
  const parent = trigger.current?.closest<HTMLElement>('.flow-screen, .app-base');
  const wasInert = parent?.inert ?? false;
  if (parent) parent.inert = true;
  const scroll = parent?.querySelector<HTMLElement>('.flow-scroll, .tab-pane:not([hidden])');
  const scrollTop = scroll?.scrollTop ?? 0;
  const scrollOverflow = scroll?.style.overflowY ?? '';
  if (scroll) scroll.style.overflowY = 'hidden';
  const overflow = document.body.style.overflow;
  document.body.style.overflow = 'hidden';
  dialog.current?.focus({ preventScroll: true });
  // Scroll only the sheet list: scrollIntoView can also move the retained form.
  const list = dialog.current?.querySelector<HTMLElement>('.data-picker-results');
  const selected = list?.querySelector<HTMLElement>('[aria-selected="true"]');
  if (list && selected) list.scrollTop = Math.max(0, selected.offsetTop - list.offsetTop - list.clientHeight + selected.offsetHeight);
  const key = (event: KeyboardEvent) => {
   if (event.key === 'Escape') { event.preventDefault(); event.stopImmediatePropagation(); closeRef.current(); }
   if (event.key !== 'Tab') return;
   const elements = Array.from(dialog.current?.querySelectorAll<HTMLElement>('button:not([disabled]), input:not([disabled])') ?? []);
   const first = elements[0], last = elements.at(-1);
   if (event.shiftKey && (document.activeElement === first || document.activeElement === dialog.current)) { event.preventDefault(); last?.focus(); }
   else if (!event.shiftKey && (document.activeElement === last || document.activeElement === dialog.current)) { event.preventDefault(); first?.focus(); }
  };
  const viewport = () => {
   const visual = window.visualViewport;
   const layer = dialog.current?.parentElement;
   if (visual && layer) { layer.style.height = `${visual.height}px`; layer.style.top = `${visual.offsetTop}px`; }
  };
  viewport();
  window.visualViewport?.addEventListener('resize', viewport);
  window.visualViewport?.addEventListener('scroll', viewport);
  document.addEventListener('keydown', key, true);
  return () => {
   if (parent) parent.inert = wasInert;
   if (scroll) { scroll.style.overflowY = scrollOverflow; scroll.scrollTop = scrollTop; }
   document.body.style.overflow = overflow;
   document.removeEventListener('keydown', key, true);
   window.visualViewport?.removeEventListener('resize', viewport);
   window.visualViewport?.removeEventListener('scroll', viewport);
   trigger.current?.focus({ preventScroll: true });
  };
 }, [open]);
 const duration = reduced || reduceSetting ? 0 : .22;
 return <>
  <Button ref={trigger} id={id} type="button" variant="outline" className="data-picker-field" disabled={disabled} aria-invalid={invalid} aria-haspopup="dialog" aria-expanded={open} onClick={() => {
   setLarge(Boolean(trigger.current?.closest('.large-text'))); setReduceSetting(Boolean(trigger.current?.closest('.reduce-motion')));
   onOpen(() => setOpen(false)); setOpen(true);
  }}><span className={value ? '' : 'data-picker-placeholder'}>{options.find(option => option.value === value)?.label ?? placeholder}</span><ChevronDown aria-hidden="true"/></Button>
  {typeof document !== 'undefined' && createPortal(<AnimatePresence>{open && <motion.div className={`data-picker-layer ${large ? 'large-text' : ''}`} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration }}>
   <div className="data-picker-backdrop" onClick={close} aria-hidden="true"/>
   <motion.div ref={dialog} role="dialog" aria-modal="true" aria-labelledby={titleId} tabIndex={-1} className="data-picker-sheet" initial={{ y: reduced || reduceSetting ? 0 : '100%' }} animate={{ y: 0 }} exit={{ y: reduced || reduceSetting ? 0 : '100%' }} transition={{ duration, ease: [.2, 0, 0, 1] }}>
    <motion.div className="data-picker-handle" aria-hidden="true" drag="y" dragConstraints={{ top: 0, bottom: 0 }} dragElastic={{ top: 0, bottom: .5 }} onDragEnd={(_, info) => { if (info.offset.y > 64 || (info.offset.y > 24 && info.velocity.y > 450)) close(); }}><span/></motion.div>
    <header className="data-picker-heading"><h2 id={titleId}>{title}</h2></header>
    <div className="data-picker-results">
     {status === 'loading' ? <Busy>Đang tải lựa chọn…</Busy> : status === 'error' ? <Notice error>Không thể tải lựa chọn.{onRetry && <Button type="button" variant="link" onClick={onRetry}>Thử lại</Button>}</Notice> : options.length ? <div role="listbox" aria-labelledby={titleId} onKeyDown={event => { const rows = Array.from(event.currentTarget.querySelectorAll<HTMLElement>('[role="option"]')); const current = rows.indexOf(document.activeElement as HTMLElement); let target; if (event.key === 'ArrowDown') target = (current + 1) % rows.length; if (event.key === 'ArrowUp') target = (current - 1 + rows.length) % rows.length; if (event.key === 'Home') target = 0; if (event.key === 'End') target = rows.length - 1; if (target !== undefined) { event.preventDefault(); rows[target]?.focus(); } }}>{options.map(option => <Button key={option.value} type="button" variant="ghost" className="data-picker-option" role="option" aria-selected={value === option.value} onClick={() => { onChange(option.value); close(); }}><span>{option.label}</span></Button>)}</div> : <p className="data-picker-empty" role="status">Chưa có lựa chọn</p>}
    </div>
   </motion.div>
  </motion.div>}</AnimatePresence>, document.body)}
 </>;
}