/**
 * Composable para formatação de valores monetários e datas.
 * Centraliza lógica de formatação evitando duplicação entre components.
 */
export function useFormatters() {
    const formatCurrency = (value) => {
        return Number(value).toFixed(2).replace('.', ',');
    };

    const formatDate = (dateStr) => {
        return new Date(dateStr).toLocaleString('pt-BR');
    };

    return {
        formatCurrency,
        formatDate
    };
}
