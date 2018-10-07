const superagent = require('superagent');
const moment = require('moment');

const sendMessage = async (text) => {
  await superagent.post(`https://api.telegram.org/bot${process.env.TOKEN}/sendMessage?chat_id=${process.env.CHAT_ID}&text=${encodeURIComponent(text)}`);
};

const mapWeatherDescription = weather => ({
  'broken clouds': '🌥',
  'scattered clouds': '⛅',
  'few clouds': '🌤',
  'clear sky': '☀️',
  'overcast clouds': '☁️️',
  'light rain': '🌧',
  'moderate rain': '🌧',
  'heavy intensity rain': '🌧🌧',
})[weather] || weather;

const getWeatherData = async () => {
  const result = (
    await superagent.get(`https://api.openweathermap.org/data/2.5/forecast?q=Braunschweig,de&APPID=${process.env.WEATHER_API_APPID}`)
  ).body.list;

  return result.filter((_, index) => index < 5)
    .map(entry => `${moment.unix(entry.dt).format('HH A')}: ${entry.weather.map(weather => mapWeatherDescription(weather.description)).join(' ')} ${(entry.main.temp - 273.15).toFixed(0)}°C`).join('\n')
};

exports.main = async () => {
  const data = await getWeatherData();

  await sendMessage(data);
};