// The Web Speech API doesn't say whether a voice is female or male: the names of the common voices of
// Microsoft (Windows and Edge's online voices), Apple and Google, by first name.

const FEMALE = `
	denise eloise vivienne hortense julie sylvie caroline nathalie charline ariane josephine coralie brigitte celeste yvette jacqueline
	ana aria ava emma jenny michelle zira libby maisie sonia hazel susan clara natasha neerja emily molly leah luna asilia ezinne rosa imani yan
	amber ashley cora elizabeth jane monica nancy sara heather linda catherine
	elvira ximena helena laura dalia sabina paloma elena salome catalina camila paola sofia maria belkys ramona andrea teresa marta karla
	yolanda margarita karina tania lorena valentina irene lucia triana estrella vera abril arabella
	samantha victoria allison zoe joelle noelle kate serena karen moira veena tessa fiona amelie audrey aurelie marie chantal
	paulina marisol angelica francisca isabela soledad
`;

const MALE = `
	henri remy paul antoine jean thierry claude gerard fabrice alain yves maurice lucien jerome
	andrew brian christopher eric guy roger steffan david mark ryan thomas george liam william prabhat connor mitchell luke wayne chilemba
	abeo james elimu sam brandon christian davis jacob jason tony ethan kai
	alvaro pablo jorge raul alonso tomas gonzalo lorenzo alex sebastian marcelo juan manuel emilio luis javier andres carlos federico roberto
	victor mario rodrigo mateo arnau dario elias nil saul teo
	alex fred tom evan nathan daniel oliver lee rishi nicolas jacques diego
`;

const names = (list: string) => new Set(list.split(/\s+/).filter(Boolean));
const FEMALES = names(FEMALE);
const MALES = names(MALE);

// "Google français" and a few others have no first name
const GOOGLE: Record<string, 'female' | 'male'> = {
	'google français': 'female',
	'google us english': 'female',
	'google español': 'male',
	'google español de estados unidos': 'female',
};

export type Gender = 'female' | 'male' | undefined;

export function gender(name: string): Gender {
	const lower = name.toLowerCase();
	if (GOOGLE[lower]) return GOOGLE[lower];
	if (/\bfemale\b/.test(lower)) return 'female';
	if (/\bmale\b/.test(lower)) return 'male';
	const first = lower
		.normalize('NFD')
		.replace(/\p{M}/gu, '')
		.match(/^[a-z]+/)?.[0];
	if (!first) return undefined;
	if (FEMALES.has(first)) return 'female';
	if (MALES.has(first)) return 'male';
	return undefined;
}
