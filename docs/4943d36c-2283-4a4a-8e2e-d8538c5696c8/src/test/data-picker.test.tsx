import { useState } from 'react';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { DataPicker } from '@/components/recipehub/data-picker';

const options = [{ value: 'tea', label: 'Trà đào cam sả' }, { value: 'matcha', label: 'Matcha Latte' }];
function Example({ status = 'ready', retry = () => {} }: { status?: 'ready' | 'loading' | 'error'; retry?: () => void }) {
 const [value, setValue] = useState('tea');
 return <DataPicker id="test-picker" title="Chọn món" value={value} options={options} onChange={setValue} status={status} onRetry={retry} onOpen={() => {}} onClose={() => {}}/>;
}
beforeEach(() => { Element.prototype.scrollIntoView = vi.fn(); });
afterEach(cleanup);
describe('Data selection sheet', () => {
 it('selects exactly one value immediately and reopens with that selection', async () => {
  render(<Example/>);
  fireEvent.click(screen.getByRole('button', { name: 'Trà đào cam sả' }));
  expect(screen.getByRole('option', { name: 'Trà đào cam sả' })).toHaveAttribute('aria-selected', 'true');
  fireEvent.click(screen.getByRole('option', { name: 'Matcha Latte' }));
  await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  fireEvent.click(screen.getByRole('button', { name: 'Matcha Latte' }));
  expect(screen.getByRole('option', { name: 'Matcha Latte' })).toHaveAttribute('aria-selected', 'true');
  expect(screen.getByRole('option', { name: 'Trà đào cam sả' })).toHaveAttribute('aria-selected', 'false');
 });
 it('dismisses without changing the previous value or focusing search', async () => {
  render(<Example/>);
  const trigger = screen.getByRole('button', { name: 'Trà đào cam sả' });
  fireEvent.click(trigger);
  fireEvent.keyDown(document, { key: 'Escape' });
  await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  expect(trigger).toHaveTextContent('Trà đào cam sả');
  expect(trigger).toHaveFocus();
 });
 it('supports keyboard navigation without changing a value until activated', () => {
  render(<Example/>);
  fireEvent.click(screen.getByRole('button', { name: 'Trà đào cam sả' }));
  const current = screen.getByRole('option', { name: 'Trà đào cam sả' });
  current.focus();
  fireEvent.keyDown(current, { key: 'ArrowDown' });
  expect(screen.getByRole('option', { name: 'Matcha Latte' })).toHaveFocus();
  expect(current).toHaveAttribute('aria-selected', 'true');
 });
 it('locks the retained form and restores its exact scroll position on dismissal', async () => {
  const view = render(<div className="flow-screen"><div className="flow-scroll"><Example/></div></div>);
  const scroll = view.container.querySelector<HTMLElement>('.flow-scroll');
  if (!scroll) throw new Error('Missing retained form');
  scroll.scrollTop = 137;
  fireEvent.click(screen.getByRole('button', { name: 'Trà đào cam sả' }));
  expect(scroll.style.overflowY).toBe('hidden');
  expect(scroll.scrollTop).toBe(137);
  fireEvent.keyDown(document, { key: 'Escape' });
  await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  expect(scroll.style.overflowY).toBe('');
  expect(scroll.scrollTop).toBe(137);
 });
 it('does not allow selection during loading or error and retries the existing source', () => {
  const retry = vi.fn();
  const view = render(<Example status="loading" retry={retry}/>);
  fireEvent.click(screen.getByRole('button', { name: 'Trà đào cam sả' }));
  expect(screen.queryAllByRole('option')).toHaveLength(0);
  view.rerender(<Example status="error" retry={retry}/>);
  expect(screen.queryAllByRole('option')).toHaveLength(0);
  fireEvent.click(screen.getByRole('button', { name: 'Thử lại' }));
  expect(retry).toHaveBeenCalledTimes(1);
 });
});