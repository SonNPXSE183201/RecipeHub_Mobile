import { useEffect, useRef, useState, type Dispatch, type SetStateAction, type RefObject } from 'react';
import { motion, useReducedMotion } from 'motion/react';
import { BookOpen, ArrowRight, List, Search, Download, Share2, ExternalLink, CheckCircle2, X, ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { bookEntries, bookGroups, searchBook, adjacentPage, bookPageCount, type ReadingPosition } from '@/lib/ebooklet';
import { recipes, sops } from '@/lib/recipe-data';
import type { NetworkMode } from '@/lib/prototype-state';
import { Notice, Busy, Empty } from './primitives';
import { BookReader } from './book-reader';

type View = 'reader' | 'contents' | 'search' | 'pdf';
export function Ebooklet({ active, onBack, position, setPosition, network, reducedSetting, failNext, consumeFailure, navigationRef, introduction = false }: {
 introduction?: boolean; active: boolean; onBack: () => void; position: ReadingPosition; setPosition: Dispatch<SetStateAction<ReadingPosition>>; navigationRef: RefObject<(() => void) | null>;
 network: NetworkMode; reducedSetting: boolean; failNext: boolean; consumeFailure: () => void;
}) {
 const [history, setHistory] = useState<View[]>([introduction ? 'contents' : 'reader']);
 const view = history.at(-1) ?? 'reader';
 const [query, setQuery] = useState('');
 const [pdfState, setPdfState] = useState<'idle' | 'creating' | 'success' | 'error'>('idle');
 const [pdfError, setPdfError] = useState('');
 const [pdf, setPdf] = useState<{ blob: Blob; url: string; pages: number } | null>(null);
 const [downloaded, setDownloaded] = useState(false);
 const [sharing, setSharing] = useState(false);
 const [shareAvailable, setShareAvailable] = useState(false);
 const reduced = useReducedMotion();
 const pending = useRef(false);
 const content = useRef<HTMLDivElement>(null);
 const results = searchBook(query);
 const duration = reduced || reducedSetting ? 0 : .16;
 const navigate = (next: View) => { if (next !== view) setHistory(previous => [...previous, next]); };
 const openPage = (page: number) => { setPosition(p => ({ ...p, started: true, page: adjacentPage(page, 0, bookPageCount), block: page === p.page ? (p.block ?? 0) : 0, offset: page === p.page ? (p.offset ?? 0) : 0 })); navigate('reader'); };
 const back = () => { if (history.length > 1) setHistory(previous => previous.slice(0, -1)); else onBack(); };
 useEffect(() => { if (!active) return; navigationRef.current = back; return () => { navigationRef.current = null; }; });
 useEffect(() => { if (!active) return; if (view !== 'reader') content.current?.querySelector<HTMLElement>(`[data-view="${view}"] h1`)?.focus({ preventScroll: true }); }, [view, active]);
 useEffect(() => { if (!pdf) return; setShareAvailable(Boolean(navigator.canShare?.({ files: [new File([pdf.blob], 'RecipeHub-so-tay.pdf', { type: 'application/pdf' })] }))); return () => URL.revokeObjectURL(pdf.url); }, [pdf]);
 const generate = async () => {
  if (pending.current) return;
  pending.current = true; setPdfState('creating'); setPdfError(''); setDownloaded(false);
  try {
   if (network === 'offline' || failNext) { if (failNext) consumeFailure(); throw new Error(network === 'offline' ? 'Đang mô phỏng mất mạng. Đổi kết nối trong Cài đặt trải nghiệm rồi thử lại.' : 'Đang mô phỏng lỗi xuất PDF. Nội dung sổ tay vẫn được giữ; bạn có thể thử lại.'); }
   const { createBookPdf } = await import('@/lib/ebooklet-pdf');
   const result = await createBookPdf();
   setPdf({ ...result, url: URL.createObjectURL(result.blob) }); setPdfState('success');
  } catch (error) { setPdfState('error'); setPdfError(error instanceof Error ? error.message : 'Không tạo được PDF. Hãy thử lại.'); }
  finally { pending.current = false; }
 };
 const download = () => { if (!pdf) return; const link = document.createElement('a'); link.href = pdf.url; link.download = 'RecipeHub-so-tay.pdf'; link.click(); setDownloaded(true); };
 const share = async () => { if (!pdf || sharing) return; setSharing(true); setPdfError(''); try { await navigator.share({ title: 'Sổ tay công thức & SOP', files: [new File([pdf.blob], 'RecipeHub-so-tay.pdf', { type: 'application/pdf' })] }); } catch (error) { if (!(error instanceof Error && error.name === 'AbortError')) setPdfError('Không chia sẻ được tệp trên thiết bị này. Bạn vẫn có thể tải hoặc mở PDF.'); } finally { setSharing(false); } };
 return <motion.section className="ebooklet-module" aria-label="Sổ tay công thức & SOP" hidden={!active} inert={!active} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration }} onKeyDown={event => { if (event.key === 'Escape' && !event.defaultPrevented) { event.preventDefault(); back(); } }}>
  <div className="handbook-content" ref={content}>
   <div className="handbook-pane handbook-reader" data-view="reader" hidden={view !== 'reader'} inert={view !== 'reader'}><BookReader active={active && view === 'reader'} position={position} setPosition={setPosition} reduced={Boolean(reduced || reducedSetting)} onClose={onBack}/></div>
   <motion.div className="handbook-pane handbook-scroll book-contents" data-view="contents" hidden={view !== 'contents'} inert={view !== 'contents'} animate={{ x: 0 }} initial={false}>
    <div className="handbook-heading"><Button variant="ghost" size="icon" aria-label="Quay lại từ Sổ tay" onClick={back}><ArrowLeft/></Button><p className="eyebrow">RecipeHub / Sổ tay</p></div>
    <h1 tabIndex={-1}>Mục lục sổ tay</h1><p className="support-note">{recipes.length} công thức · {sops.length} quy trình SOP</p>
    {bookGroups.map(group => <section key={group}><h2>{group}</h2>{bookEntries.map((item, index) => item.group === group && <Button key={item.name} variant="ghost" className="action-row book-contents-row" aria-current={position.started && position.page === index ? 'page' : undefined} onClick={() => openPage(index)}><span><strong>{item.name}</strong><small>{item.kind === 'sop' ? 'SOP' : 'Công thức'} · {item.steps.length} bước</small></span><span className="book-page-number">{index + 1}</span><ArrowRight/></Button>)}</section>)}
    <Button variant="ghost" className="action-row" onClick={() => openPage(bookPageCount - 1)}><span><strong>Trang kết thúc</strong></span><span className="book-page-number">{bookPageCount}</span><ArrowRight/></Button>
   </motion.div>
   <motion.div className="handbook-pane handbook-scroll book-search" data-view="search" hidden={view !== 'search'} inert={view !== 'search'} animate={{ x: 0 }} initial={false}>
    <div className="handbook-heading"><Button variant="ghost" size="icon" aria-label="Quay lại từ Tìm trong sổ tay" onClick={back}><ArrowLeft/></Button><p className="eyebrow">RecipeHub / Sổ tay</p></div>
    <h1 tabIndex={-1}>Tìm trong sổ tay</h1><div className="search-box"><Search/><input type="search" aria-label="Tên công thức hoặc SOP trong sổ tay" placeholder="Tên công thức hoặc SOP…" value={query} onChange={e => setQuery(e.target.value)}/>{query && <Button variant="ghost" size="icon" aria-label="Xóa tìm kiếm sổ tay" onClick={() => setQuery('')}><X/></Button>}</div><p className="support-note">{results.length} kết quả</p>
    {results.map(({ entry: item, index }) => <Button variant="ghost" className="action-row" key={item.name} onClick={() => openPage(index)}><span><strong>{item.name}</strong><small>{item.kind === 'sop' ? 'Quy trình SOP' : `Công thức · ${item.group}`}</small></span><span className="book-page-number">{index + 1}</span><ArrowRight/></Button>)}
    {!results.length && <Empty title="Không có kết quả"><Button variant="outline" onClick={() => setQuery('')}>Xóa tìm kiếm</Button></Empty>}
   </motion.div>
   <motion.div className="handbook-pane handbook-scroll book-pdf" data-view="pdf" hidden={view !== 'pdf'} inert={view !== 'pdf'} animate={{ x: 0 }} initial={false}>
    <div className="handbook-heading"><Button variant="ghost" size="icon" aria-label="Quay lại từ Xuất sổ tay PDF" onClick={back}><ArrowLeft/></Button><p className="eyebrow">RecipeHub / Sổ tay</p></div>
    <h1 tabIndex={-1}>Xuất sổ tay PDF</h1><p className="book-cover-description">{recipes.length} công thức và {sops.length} quy trình SOP, gồm định lượng, các bước và lưu ý có trong dữ liệu mẫu.</p><Notice>Tài liệu mẫu chưa được cửa hàng phê duyệt. PDF được tạo từ nội dung hiện có, không phải dữ liệu Firebase của app thật.</Notice>
    {pdfState === 'creating' ? <Busy>Đang tạo PDF…</Busy> : pdfState === 'success' && pdf ? <div className="book-pdf-result"><CheckCircle2/><h2>PDF đã tạo xong</h2><p>{pdf.pages} trang PDF · {(pdf.blob.size / 1024).toFixed(0)} KB</p><Button onClick={download}><Download/>{downloaded ? 'Tải lại PDF' : 'Tải PDF'}</Button>{downloaded && <p className="support-note">Đã yêu cầu trình duyệt tải tệp. Kiểm tra thư mục tải xuống trên thiết bị.</p>}<Button variant="outline" onClick={() => window.open(pdf.url, '_blank', 'noopener,noreferrer')}><ExternalLink/>Mở PDF</Button>{shareAvailable && <Button variant="outline" disabled={sharing} onClick={() => void share()}><Share2/>{sharing ? 'Đang chia sẻ…' : 'Chia sẻ PDF'}</Button>}</div> : <Button className="book-start" onClick={() => void generate()}><Download/>{pdfState === 'error' ? 'Thử tạo lại PDF' : 'Tạo PDF đầy đủ'}</Button>}
    {pdfError && <Notice error>{pdfError}</Notice>}
   </motion.div>
  </div>
  <nav className="handbook-navigation" aria-label="Điều hướng Sổ tay">
   <div className="handbook-capsule">{([{ id: 'reader', label: 'Đọc tiếp', icon: BookOpen }, { id: 'contents', label: 'Mục lục', icon: List }, { id: 'pdf', label: 'PDF', icon: Download }] as const).map(item => <Button key={item.id} variant="ghost" className="handbook-nav-item" aria-current={view === item.id ? 'page' : undefined} onClick={() => navigate(item.id)}>{view === item.id && <motion.span className="handbook-nav-indicator" layoutId="handbook-nav-indicator" transition={{ duration }}/>}<item.icon aria-hidden="true"/><span>{item.label}</span></Button>)}</div>
   <Button variant="ghost" size="icon" className="handbook-search-button" aria-label="Tìm trong sổ tay" aria-current={view === 'search' ? 'page' : undefined} title="Tìm trong sổ tay" onClick={() => navigate('search')}><Search/></Button>
  </nav>
 </motion.section>;
}
