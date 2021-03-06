import { SettingPeroid } from 'container/GeneralSettings';

const converIntoHr = (value: number, peroid: SettingPeroid): number => {
	if (peroid === 'day') {
		return value * 24;
	}

	if (peroid === 'hr') {
		return value;
	}

	return value * 720;
};

export default converIntoHr;
