// errors/l02_html.tsx
function tuningName({ name }: { name: string }) {
  return <h2 class="tuning-name">{name}</h2>;
}

export function Examples() {
  return (
    <label for="capo">
      <tuningName name="Standard" />
      <input id="capo" type="number" min={0} max="12" onchange={() => {}} />
    </label>
  );
}
