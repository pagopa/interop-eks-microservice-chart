-- Links product to tenant by adding a tenant_id foreign key.
-- This migration depends on the tenant table created in V1 (step 1).
ALTER TABLE product
    ADD COLUMN IF NOT EXISTS tenant_id UUID,
    ADD CONSTRAINT fk_product_tenant
        FOREIGN KEY (tenant_id)
        REFERENCES tenant (id)
        ON DELETE SET NULL;
