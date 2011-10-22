/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
import java.net.UnknownHostException;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Timer;
import java.util.TimerTask;

import org.bson.types.ObjectId;

import com.mongodb.BasicDBObject;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.DBObject;
import com.mongodb.MapReduceCommand;
import com.mongodb.MapReduceCommand.OutputType;
import com.mongodb.MapReduceOutput;
import com.mongodb.Mongo;
import com.mongodb.MongoException;

public class Main {

	private final static Map<String, SimulationParameter> simulatedSensors = new HashMap<String, SimulationParameter>();

	static {
		simulatedSensors.put("CUBE_TEMPERATURE", new SimulationParameter(2030,
				2600, 3));
		simulatedSensors.put("CUBE_ILLUMINANCE", new SimulationParameter(200,
				15000, 50));

		simulatedSensors.put("STATION1_TEMPERATURE", new SimulationParameter(
				1900, 2650, 1));
		simulatedSensors.put("STATION1_ILLUMINANCE", new SimulationParameter(
				200, 15000, 20));

		simulatedSensors.put("STATION2_TEMPERATURE", new SimulationParameter(
				1980, 2450, 2));
		simulatedSensors.put("STATION2_ILLUMINANCE", new SimulationParameter(
				200, 15000, 80));
	}

	private static Map<String, Integer> consolidationJobs = new HashMap<String, Integer>();
	static {
		consolidationJobs.put("consolidatedData_OneMinute", 60 * 1000);
		consolidationJobs.put("consolidatedData_FiveMinute", 5 * 60 * 1000);
		consolidationJobs.put("consolidatedData_OneHour", 60 * 60 * 1000);
	}

	public static void main(String[] args) {
		Mongo m;

		List<String> argsList = Arrays.asList(args);

		try {
			m = new Mongo("91.121.117.128", 27017);
			DB db = m.getDB("sensors");
			final DBCollection sensorsCollection = db.getCollection("data");

			if (argsList.contains("-resetSensorInfo")) {
				DBCollection infoCollection = db.getCollection("info");

				System.out.println("Resetting sensors/info collection");
				resetInfoCollection(infoCollection);
				System.out.println("... done");

				System.exit(0);
			}

			// schedule data consolidation jobs
			int delay = 0;
			for (final Entry<String, Integer> entry : consolidationJobs
					.entrySet()) {
				Timer t = new Timer(entry.getKey() + " consolidation job");

				t.schedule(new TimerTask() {
					@Override
					public void run() {
						performMapReduce(sensorsCollection, entry.getKey(),
								entry.getValue());
					}
				}, (5 * delay++ * 1000), 20 * 1000);

			}

			if (argsList.contains("-simulate")) {
				System.out.println("Starting simulation");
				while (true) {
					for (Entry<String, SimulationParameter> entry : simulatedSensors
							.entrySet()) {
						String sensorName = entry.getKey();
						SimulationParameter simulationParameter = entry
								.getValue();

						SensorData sensorData = null;
						if (sensorName.endsWith("TEMPERATURE")) {
							sensorData = new SensorData(sensorName,
									simulationParameter.updateValue() / 100.0);
						} else {
							sensorData = new SensorData(sensorName,
									simulationParameter.updateValue());
						}
						System.out.println(sensorData);
						sensorsCollection.insert(sensorData);
					}
					Thread.sleep(5000);
				}
			}
		} catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (MongoException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	private static void resetInfoCollection(DBCollection infoCollection) {
		infoCollection.drop();

		infoCollection.insert(new SensorInfo("CUBE_TEMPERATURE",
				"Temperature at the cube", "°C"));
		infoCollection.insert(new SensorInfo("CUBE_ILLUMINANCE",
				"Ambient light level at the cube", "lux"));

		infoCollection.insert(new SensorInfo("STATION1_TEMPERATURE",
				"Temperature at station #1", "°C"));
		infoCollection.insert(new SensorInfo("STATION1_ILLUMINANCE",
				"Ambient light level at station #1", "lux"));

		infoCollection.insert(new SensorInfo("STATION2_TEMPERATURE",
				"Temperature at station #2", "°C"));
		infoCollection.insert(new SensorInfo("STATION2_ILLUMINANCE",
				"Ambient light level at station #2", "lux"));
	}

	private static void performMapReduce(DBCollection collection,
			String outputCollection, int interval) {
		System.out
				.println("Consolidating data for " + outputCollection + "...");

		String map = "function() {\r\n"
				+ "            emit( {sensorId: this.sensor, ts: new Date(parseInt( (this._id.getTimestamp()/ INTERVAL) + \"\" ) * INTERVAL)} , { sensorId: this.sensor, total: this.value, min: this.value, max: this.value, count: 1  } );\r\n"
				+ "};";

		String reduce = "function( key , values ){\r\n"
				+ "    var total = 0;\r\n"
				+ "    var min = 0;\r\n"
				+ "    var max = 0;\r\n"
				+ "    var count = 0;\r\n"
				+ "    for ( var i=0; i<values.length; i++ ) {\r\n"
				+ "        var v = values[i];\r\n"
				+ "        if (i == 0) {\r\n"
				+ "            min = v.min ;\r\n"
				+ "            max = v.max ;\r\n"
				+ "        }\r\n"
				+ "        total += v.total;\r\n"
				+ "        count += v.count;\r\n"
				+ "        min = Math.min(v.min, min);\r\n"
				+ "        max = Math.max(v.max, max);\r\n"
				+ "    }\r\n"
				+ "    return { sensorId: key.sensorId, total: total, min: min, max: max, count: count };\r\n"
				+ "};";

		String finalize = "function ( who , res ){\r\n"
				+ "    var avg = res.total / res.count;\r\n"
				+ "    avg = Math.round(avg*100)/100;\r\n"
				+ "    return {sensorId: res.sensorId, nbSamples: res.count, average: avg, minimum: res.min, maximum: res.max};\r\n"
				+ "}";

		// we consolidate only the data received on the last interval
		long startingPoint = (System.currentTimeMillis() / interval) * interval;
		DBObject query = new BasicDBObject();
		// System.out.println(Long.toHexString(startingPoint / 1000)
		// + "000000000000000000");
		query.put("_id", new BasicDBObject("$gte", new ObjectId(new Date(
				startingPoint))));

		MapReduceCommand mrc = new MapReduceCommand(collection, map, reduce,
				outputCollection, OutputType.MERGE, query);

		mrc.setFinalize(finalize);

		Map<String, Object> scope = new HashMap<String, Object>();
		scope.put("INTERVAL", interval);
		mrc.setScope(scope);

		MapReduceOutput result = collection.mapReduce(mrc);

		System.out.println("... data consolidation for " + outputCollection
				+ "... done in " + result.getRaw().get("timeMillis") + "ms.");
	}
}
