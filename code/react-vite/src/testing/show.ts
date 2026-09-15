// What the course's tests print: the HTML that a component rendered, indented, without colors
import { prettyDOM } from '@testing-library/dom';

export function showHtml(label: string, element: Element): void {
  console.log(`${label}\n${prettyDOM(element, Infinity, { highlight: false })}`);
}
