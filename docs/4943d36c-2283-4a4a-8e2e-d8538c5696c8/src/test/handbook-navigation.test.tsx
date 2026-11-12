import { useRef, useState } from 'react';
import { cleanup, fireEvent, render, screen } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { Ebooklet } from '@/components/recipehub/ebooklet';
import { bookEntries, initialReadingPosition } from '@/lib/ebooklet';

const createPdf = vi.fn();
vi.mock('@/lib/ebooklet-pdf', () => ({ createBookPdf: createPdf }));
vi.mock('@/components/recipehub/book-reader', () => ({ BookReader: ({ position }: { position: { page: number } }) => <output data-testid="reading-anchor">{position.page}</output> }));
function Example() {
 const [position, setPosition] = useState(initialReadingPosition);
 const navigationRef = useRef<(() => void) | null>(null);
 return <Ebooklet active onBack={() => {}} position={position} setPosition={setPosition} navigationRef={navigationRef} network="online" reducedSetting failNext={false} consumeFailure={() => {}}/>;
}
afterEach(() => { cleanup(); vi.clearAllMocks(); });
describe('Handbook retained navigation', () => {
 it('opens the exact SOP from search and retains its query and reading anchor across screens', () => {
  render(<Example/>);
  fireEvent.click(screen.getByRole('button', { name: 'Tìm trong sổ tay' }));
  fireEvent.change(screen.getByRole('searchbox'), { target: { value: 've sinh may' } });
  fireEvent.click(screen.getByRole('button', { name: /Vệ sinh máy espresso/ }));
  const expected = bookEntries.findIndex(entry => entry.name === 'Vệ sinh máy espresso');
  expect(Number(screen.getByTestId('reading-anchor').textContent)).toBe(expected);
  fireEvent.click(screen.getByRole('button', { name: 'Mục lục' }));
  fireEvent.click(screen.getByRole('button', { name: 'Tìm trong sổ tay' }));
  expect(screen.getByRole('searchbox')).toHaveValue('ve sinh may');
  fireEvent.click(screen.getByRole('button', { name: 'Đọc tiếp' }));
  expect(Number(screen.getByTestId('reading-anchor').textContent)).toBe(expected);
 });
 it('does not start PDF creation when switching to PDF', () => {
  render(<Example/>);
  fireEvent.click(screen.getByRole('button', { name: 'PDF' }));
  expect(createPdf).not.toHaveBeenCalled();
 });
});