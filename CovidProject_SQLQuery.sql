SELECT * 
FROM dbo.CovidDeaths
WHERE continent <> ' '
ORDER BY 3,4

SELECT *
FROM dbo.CovidVaccinations
ORDER BY 3,4

--SELECT DATA that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, new_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
FROM CovidProject..CovidDeaths
WHERE total_cases > 0
AND total_deaths >0
AND location LIKE '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT Location, date, total_cases, Population, new_cases, (cast(total_cases as float)/cast(population as float))*100 as InfectionRate
FROM CovidProject..CovidDeaths
WHERE total_cases > 0
AND location LIKE '%states%'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((cast(total_cases as float)/cast(population as float))*100) as InfectionRate
FROM CovidProject..CovidDeaths
-- WHERE location LIKE '%states%'
GROUP BY Location, Population
ORDER BY InfectionRate Desc

-- Looking at Countries with Highest Death Count
SELECT Location, Population, MAX(cast(total_deaths AS int)) as TotalDeathCount, total_deaths, cast(total_deaths as float)/cast(population as float)*100 as DeathRate
FROM CovidProject..CovidDeaths
WHERE continent <> ' '
GROUP BY Location, Population, total_deaths
ORDER BY DeathRate Desc

-- Continents with Highest Death Count
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Covidproject..CovidDeaths
WHERE continent <> ' '
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Global numbers by day
SELECT date, SUM(cast(new_cases as float)) AS TotalCases, SUM(cast(new_deaths as float)) AS TotalDeaths, SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent <> ' ' AND new_cases <> 0
GROUP BY date
ORDER BY 1,2

-- Global numbers total
SELECT SUM(cast(new_cases as float)) AS TotalCases, SUM(cast(new_deaths as float)) AS TotalDeaths, SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent <> ' ' AND new_cases <> 0
ORDER BY 1,2

-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccs
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ' '
    AND new_vaccinations <> ' '
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
ORDER BY 2,3


-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, CumulativeVaccs)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccs
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ' '
    AND new_vaccinations <> ' '
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
-- ORDER BY 2,3
)
SELECT *, CONVERT(float,(CumulativeVaccs)/CONVERT(float,Population))*100 AS PopulationPercentage
FROM PopvsVac

-- TEMP TABLE
DROP TABLE IF exists #PercentageVaccinated
CREATE TABLE #PercentageVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
DATE datetime,
Population float,
new_vaccinations int,
CumulativeVaccs float
)
INSERT INTO #PercentageVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccs
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ' '
    AND new_vaccinations <> ' '
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
-- ORDER BY 2,3
SELECT *, (CumulativeVaccs/Population)*100 AS PopulationPercentage
FROM #PercentageVaccinated


-- View for Visualizations in Tableau
CREATE VIEW PopulationPercentage AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccs
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ' '
    AND new_vaccinations <> ' '
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
-- ORDER BY 2,3

-- Using previously made View
SELECT *
FROM PopulationPercentage