import axios from 'axios';

const { apiHost = '' } = window.worqchatConfig || {};
const wootAPI = axios.create({ baseURL: `${apiHost}/` });

export default wootAPI;
