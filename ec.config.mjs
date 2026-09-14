import { defineEcConfig } from '@astrojs/starlight/expressive-code';

// Tables printed by database CLIs are drawn with box-drawing characters: at the default line height
// their vertical borders break into dashes, so blocks that contain them get a tighter one.
const boxDrawing = {
	name: 'box-drawing',
	baseStyles: '.box-drawing .ec-line { line-height: 1.2; }',
	hooks: {
		postprocessRenderedBlock: ({ codeBlock, renderData }) => {
			if (!/[─-╿]/.test(codeBlock.code)) return;
			const properties = renderData.blockAst.properties;
			properties.className = [...(properties.className ?? []), 'box-drawing'];
		},
	},
};

export default defineEcConfig({
	plugins: [boxDrawing],
});
