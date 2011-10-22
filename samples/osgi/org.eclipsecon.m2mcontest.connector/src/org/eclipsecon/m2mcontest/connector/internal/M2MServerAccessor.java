/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
package org.eclipsecon.m2mcontest.connector.internal;

import java.net.URI;

import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.UriBuilder;

import org.eclipsecon.m2mcontest.connector.CONSOLIDATION_RANGE;
import org.eclipsecon.m2mcontest.connector.IM2MServerAccessor;
import org.eclipsecon.m2mcontest.connector.M2MContestConstants;
import org.eclipsecon.m2mcontest.connector.resources.consolidatedData.ConsolidatedData;
import org.eclipsecon.m2mcontest.connector.resources.data.Data;
import org.eclipsecon.m2mcontest.connector.resources.info.Info;

import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.api.client.config.ClientConfig;
import com.sun.jersey.api.client.config.DefaultClientConfig;

public class M2MServerAccessor implements IM2MServerAccessor {

	private static final int DEFAULT_BATCH_SIZE = 100;
	private WebResource service;

	public M2MServerAccessor() {
		ClientConfig config = new DefaultClientConfig();
		Client client = Client.create(config);
		service = client.resource(getBaseURI());
	}

	@Override
	public Data getSensorData(String criteria, String sort) {
		return getSensorData(criteria, sort, 100);
	}

	@Override
	public Data getSensorData(String criteria, String sort, int maxResults) {
		WebResource resource = service.path("sensors").path("data");
		resource = appendQueryParams(resource, criteria, sort, maxResults);
		ClientResponse clientResponse = resource.accept(
				MediaType.APPLICATION_JSON_TYPE).get(ClientResponse.class);
		return clientResponse.getEntity(Data.class);
	}

	@Override
	public ConsolidatedData getSensorConsolidatedData(
			CONSOLIDATION_RANGE range, String criteria, String sort) {
		return getSensorConsolidatedData(range, criteria, sort,
				DEFAULT_BATCH_SIZE);
	}

	@Override
	public ConsolidatedData getSensorConsolidatedData(
			CONSOLIDATION_RANGE range, String criteria, String sort,
			int maxResults) {
		WebResource resource = service.path("sensors").path(
				"consolidatedData_" + range.collectionSuffix);
		resource = appendQueryParams(resource, criteria, sort, maxResults);
		ClientResponse clientResponse = resource.accept(
				MediaType.APPLICATION_JSON_TYPE).get(ClientResponse.class);
		return clientResponse.getEntity(ConsolidatedData.class);
	}

	@Override
	public Info getSensorInfo(String criteria, String sort) {
		return getSensorInfo(criteria, sort, DEFAULT_BATCH_SIZE);
	}

	@Override
	public Info getSensorInfo(String criteria, String sort, int maxResults) {
		WebResource resource = service.path("sensors").path("info");
		resource = appendQueryParams(resource, criteria, sort, maxResults);
		ClientResponse clientResponse = resource.accept(
				MediaType.APPLICATION_JSON_TYPE).get(ClientResponse.class);
		return clientResponse.getEntity(Info.class);
	}

	private static URI getBaseURI() {
		return UriBuilder.fromUri(M2MContestConstants.BASE_URL).build();
	}

	private WebResource appendQueryParams(WebResource resource,
			String criteria, String sort, int maxResults) {
		WebResource result = resource;
		if (criteria != null) {
			result = result.queryParam("criteria", criteria);
		}
		if (sort != null) {
			result = result.queryParam("sort", sort);
		}
		result = result.queryParam("batch_size", maxResults + "");
		return result;
	}
}
