const CAREER_START_YEAR = 2015;

async function currentYear() {
  try {
    const response = await fetch(location.href, { method: 'HEAD', cache: 'no-store' });
    const dateHeader = response.headers.get('Date');
    if (response.ok && dateHeader) {
      const serverDate = new Date(dateHeader);
      if (!isNaN(serverDate)) {
        return serverDate.getFullYear();
      }
    }
  } catch (e) {}
  return new Date().getFullYear();
}

function showDates(thisYear) {
  const experience = thisYear - CAREER_START_YEAR;

  document.querySelectorAll('.experience').forEach((el) => {
    el.textContent = experience;
  });

  document.querySelectorAll('.year').forEach((el) => {
    el.textContent = thisYear;
  });
}

showDates(await currentYear());
