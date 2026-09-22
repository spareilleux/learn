package dev.learn.spring.l05;

import org.springframework.data.r2dbc.core.R2dbcEntityTemplate;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public final class VoicingCatalog {
    private final R2dbcEntityTemplate template;

    public VoicingCatalog(R2dbcEntityTemplate template) {
        this.template = template;
    }

    public Mono<Voicing> save(Voicing voicing) {
        return template.insert(voicing);
    }

    public Flux<Voicing> findBySymbol(String symbol) {
        return template.select(Voicing.class)
                .matching(org.springframework.data.relational.core.query.Query.query(
                        org.springframework.data.relational.core.query.Criteria.where("symbol").is(symbol)))
                .all();
    }
}
