import styled from 'styled-components';

interface Props {
	isDashboardPage: boolean;
}
export const ValueContainer = styled.div<Props>`
	height: ${({ isDashboardPage }): string =>
		isDashboardPage ? '100%' : '55vh'};
	display: flex;
	justify-content: center;
	align-items: center;
	flex-direction: column;
`;

export const TitleContainer = styled.div<Props>`
	text-align: center;
	padding-top: ${({ isDashboardPage }): string =>
		!isDashboardPage ? '1rem' : '0rem'};
`;
