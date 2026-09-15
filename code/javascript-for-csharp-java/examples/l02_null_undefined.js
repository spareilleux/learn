// Lesson 2: two absent values, undefined and null
import { attempt, show } from './show.js';

let notAssigned;
const page = { title: 'Mission', order: 0, draft: null };

function noReturn() {}
function greet(name) {
  return name;
}

show('notAssigned', notAssigned);
show('page.author', page.author);
show('noReturn()', noReturn());
show('greet()', greet());
show('page.draft', page.draft);
show('typeof page.draft', typeof page.draft);

attempt('page.author.name', () => page.author.name);
show('page.author?.name', page.author?.name);
show("page.author ?? 'anonymous'", page.author ?? 'anonymous');

// || replaces every falsy value, ?? only null and undefined
show('page.order || 99', page.order || 99);
show('page.order ?? 99', page.order ?? 99);

show('JSON.stringify(page)', JSON.stringify({ ...page, author: undefined }));
show('null == undefined', null == undefined);
show('null === undefined', null === undefined);
