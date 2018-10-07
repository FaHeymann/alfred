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
  'moderate rain': '🌧🌧',
  'heavy intensity rain': '🌧🌧🌧',
})[weather] || weather;

const getWeatherData = async () => {
  const result = (
    await superagent.get(`https://api.openweathermap.org/data/2.5/forecast?q=Braunschweig,de&APPID=${process.env.WEATHER_API_APPID}`)
  ).body.list;

  return result.filter((_, index) => index < 5)
    .map(
      entry => `${moment.unix(entry.dt).format('HH A')}: ${entry.weather
        .map(
          weather => mapWeatherDescription(weather.description)
        )
        .join(' ')} ${(entry.main.temp - 273.15).toFixed(0)}°C`
    );
};

const getTodos = async () => {
  const result = await superagent.get('https://habitica.com/api/v3/tasks/user?type=todos')
    .set('x-api-user', process.env.HABITICA_USER_ID)
    .set('x-api-key', process.env.HABITICA_API_TOKEN);

  return result.body.data.map(e => e.text);
};

exports.main = async () => {
  const output = ['Wetter:']
    .concat(await getWeatherData())
    .concat(['', 'Todos:'])
    .concat(await getTodos());

  await sendMessage(output.join('\n'));
};
